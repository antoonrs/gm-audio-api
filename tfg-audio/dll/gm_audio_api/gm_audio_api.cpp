/*
DLL para GameMaker basada en miniaudio que ofrece
- Reproduccion basica de archivos con play/pause/resume/stop/loop/volume
- Transport musical (bpm, play/pause/stop y lectura de la posicion en beats)
- Lanzamiento cuantizado de sonidos al siguiente beat (play_on_beat)
- Carga de BPM desde un JSON simple (mediante micro-parser con regex)

Cuestiones:
- Thread-safety: se usa un mutex global (gMutex) para proteger todos los estados compartidos (mapas, colas y el transport)
- Transport: se calcula el beat como baseBeat + dt*(bpm/60). baseBeat se actualiza al pausar/cambiar bpm para evitar saltos
- Cuantizacion: se programa un lanzamiento con targetBeat un tick (llamado desde GML en Step) libera los sonidos cuya hora haya llegado.
- JSON: se busca el campo "bpm" con regular expresions.

Requisitos:
- GameMaker debe llamar a gm_audio_transport_tick() cada Step si usa cuantizacion.
*/

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include <unordered_map>
#include <vector>
#include <mutex>
#include <atomic>
#include <string>
#include <chrono>
#include <cmath>
#include <fstream>
#include <sstream>
#include <regex>
#include <cctype>

////////////////////////////////////////////////////////////////////////////////////////
// Estado global del engine y recursos basicos
////////////////////////////////////////////////////////////////////////////////////////

// Motor de miniaudio
static ma_engine gEngine;
static bool gEngineIniciado = false;

// Mapas de sonidos activos y su posicion pausada (en frames PCM)
static std::unordered_map<int, ma_sound*> gSounds;
static std::unordered_map<int, ma_uint64> gPausedFrame;

// protege todas las estructuras globales mediante mutex
static std::mutex gMutex;
// generador atomico de IDS
static std::atomic<int> gNextId{ 1 };
static inline int makeId() { return gNextId.fetch_add(1); }



////////////////////////////////////////////////////////////////////////////////////////
// TRANSPORT MUSICAL bpm y reloj de beats
// - bpm: tempo
// - baseBeat: acumulado hasta el ultimo play/pause/cambio de bpm
// - startTime: instante en que se reanudo para integrar el dt
////////////////////////////////////////////////////////////////////////////////////////
struct Transport {
    std::atomic<bool> playing{ false };
    std::atomic<double> bpm{ 120.0 };
    double baseBeat = 0.0;
    std::chrono::high_resolution_clock::time_point startTime;
} static gTransport;

// calcula el beat actual SIN tomar el mutex (se asume que el llamador ya bloqueo)
static inline double transport_get_beat_unlocked() {
    if (!gTransport.playing.load()) return gTransport.baseBeat;
    using clock = std::chrono::high_resolution_clock;
    const double dt = std::chrono::duration<double>(clock::now() - gTransport.startTime).count();
    return gTransport.baseBeat + dt * (gTransport.bpm.load() / 60.0);
}

////////////////////////////////////////////////////////////////////////////////////////
// COLA DE LANZAMIENTOS CUANTIZADOS
// - se programa un sonido para un beat objetivo (targetBeat)
// - el tick (desde GML) verifica cuando dispararlo
////////////////////////////////////////////////////////////////////////////////////////
struct ActiveVoice {
    ma_sound* sound = nullptr;
    int id = 0;
};

struct PendingStop {
    ma_sound* voice = nullptr;
    double endBeat = 0.0;
};

struct PendingLaunch {
    int id;
    double targetBeat;
};

////////////////////////////////////////////////////////////////////////////////////////
// UTILDADES DE ARCHIVO Y PARSER JSON
////////////////////////////////////////////////////////////////////////////////////////
static std::vector<PendingLaunch> gQueue;
static std::vector<ActiveVoice> gActiveVoices;
static std::vector<PendingStop> gPendingStops;
static std::vector<ma_sound*> gPendingDelete;

// Lee un archivo de texto completo a memoria
static bool readTextFile(const char* path, std::string& out) {
    std::ifstream ifs(path, std::ios::binary);
    if (!ifs) return false;
    std::ostringstream ss;
    ss << ifs.rdbuf();
    out = ss.str();
    return true;
}

// Extrae el valor numerico de bpm desde un JSON
static bool json_extract_bpm(const std::string& txt, double& bpmOut) {
    static const std::regex re(R"("bpm"\s*:\s*([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?))");
    std::smatch m;
    if (std::regex_search(txt, m, re) && m.size() >= 2) {
        try {
            bpmOut = std::stod(m[1].str());
            return true;
        }
        catch (...) {
            return false;
        }
    }
    return false;
}

static std::string path_dirname(const std::string& p) {
    size_t i = p.find_last_of("/\\");
    return (i == std::string::npos) ? std::string() : p.substr(0, i + 1);
}
static std::string path_join(const std::string& a, const std::string& b) {
    if (a.empty()) return b;
    if (b.empty()) return a;
    char last = a.back();
    if (last == '\\' || last == '/') return a + b;
    return a + "\\" + b;
}

static int note_name_to_midi(const std::string& note) {
    if (note.empty()) return -1;
    static const std::unordered_map<std::string, int> base = {
        {"C",0},{"C#",1},{"DB",1},{"D",2},{"D#",3},{"EB",3},{"E",4},{"F",5},{"F#",6},{"GB",6},
        {"G",7},{"G#",8},{"AB",8},{"A",9},{"A#",10},{"BB",10},{"B",11}
    };
    std::string notePart;
    std::string octavePart;
    for (char c : note) {
        if ((c >= '0' && c <= '9') || c == '-') octavePart.push_back(c);
        else notePart.push_back((char)toupper(c));
    }
    if (notePart.empty() || octavePart.empty()) return -1;
    auto it = base.find(notePart);
    if (it == base.end()) return -1;
    int octave = std::stoi(octavePart);
    return 12 * (octave + 1) + it->second;
}

static double pitch_from_semitones(double delta, double cents = 0.0) {
    return std::pow(2.0, (delta + cents / 100.0) / 12.0);
}


static void schedule_sound_delete(ma_sound* s) {
    if (!s) return;
    // añadimos a la lista de borrado diferido (el caller debe tomar gMutex)
    gPendingDelete.push_back(s);
}


////////////////////////////////////////////////////////////////////////////////////////
// SECUENCIADOR DE CANCION
////////////////////////////////////////////////////////////////////////////////////////
struct SongEvent {
    std::string path;
    ma_sound* sound = nullptr;
    double offsetBeat = 0.0;
    double nextBeat = 0.0;
    double dur = 0.0;
    float vel = 1.0f;
    bool active = true;
};

struct Song {
    bool loaded = false;
    bool loop = false;
    int beatsPerBar = 4;
    int bars = 1;
    double startBeat = 0.0;
    std::vector<SongEvent> events;
} static gSong;

static bool json_extract_bool(const std::string& txt, const char* key, bool& out) {
    std::regex re(std::string("\"") + key + R"("\s*:\s*(true|false))", std::regex::icase);
    std::smatch m;
    if (std::regex_search(txt, m, re) && m.size() >= 2) {
        std::string v = m[1].str();
        out = (v == "true" || v == "TRUE");
        return true;
    }
    return false;
}

static bool json_extract_int(const std::string& txt, const char* key, int& out) {
    std::regex re(std::string("\"") + key + R"("\s*:\s*(-?\d+))");
    std::smatch m;
    if (std::regex_search(txt, m, re) && m.size() >= 2) {
        out = std::stoi(m[1].str());
        return true;
    }
    return false;
}

static bool json_extract_events(const std::string& txt, std::vector<SongEvent>& out) {
    out.clear();
    const std::regex reFile(R"(\{\s*\"file\"\s*:\s*\"([^\"]+)\"\s*,\s*\"beat\"\s*:\s*([-+]?\d*\.?\d+)\s*(?:,\s*\"dur\"\s*:\s*([-+]?\d*\.?\d+))?\s*(?:,\s*\"vel\"\s*:\s*([-+]?\d*\.?\d+))?\s*\})");
    const std::regex reNote(R"(\{\s*\"note\"\s*:\s*\"([A-Ga-g][#b]?\-?\d+)\"\s*,\s*\"beat\"\s*:\s*([-+]?\d*\.?\d+)\s*(?:,\s*\"dur\"\s*:\s*([-+]?\d*\.?\d+))?\s*(?:,\s*\"vel\"\s*:\s*([-+]?\d*\.?\d+))?\s*\})");
    for (auto it = std::sregex_iterator(txt.begin(), txt.end(), reFile); it != std::sregex_iterator(); ++it) {
        SongEvent ev;
        ev.path = (*it)[1].str();
        ev.offsetBeat = std::stod((*it)[2].str());
        if ((*it).size() >= 3 && (*it)[3].matched) ev.dur = std::stod((*it)[3].str());
        if ((*it).size() >= 4 && (*it)[4].matched) ev.vel = (float)std::stod((*it)[4].str());
        out.push_back(ev);
    }
    for (auto it = std::sregex_iterator(txt.begin(), txt.end(), reNote); it != std::sregex_iterator(); ++it) {
        SongEvent ev;
        ev.path = std::string("NOTE:") + (*it)[1].str();
        ev.offsetBeat = std::stod((*it)[2].str());
        if ((*it).size() >= 3 && (*it)[3].matched) ev.dur = std::stod((*it)[3].str());
        if ((*it).size() >= 4 && (*it)[4].matched) ev.vel = (float)std::stod((*it)[4].str());
        out.push_back(ev);
    }
    return !out.empty();
}






////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
// API C exportada para GameMaker
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

extern "C" {


    // Inicializa miniaudio y limpia estados
    __declspec(dllexport) double gm_audio_init() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (gEngineIniciado) return 1.0;

        ma_result res = ma_engine_init(NULL, &gEngine);
        if (res == MA_SUCCESS) {
            gEngineIniciado = true;

            // Resetea estructuras globales
            gSounds.clear();
            gPausedFrame.clear();
            gQueue.clear();

            // Transport por defecto
            gTransport.playing.store(false);
            gTransport.bpm.store(120.0);
            gTransport.baseBeat = 0.0;

            return 1.0;
        }
        return 0.0;
    }

    // Apaga el engine y libera todos los sonidos
    __declspec(dllexport) double gm_audio_shutdown() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gEngineIniciado) return 1.0;
        for (auto& kv : gSounds) {
            schedule_sound_delete(kv.second);
        }
        gSounds.clear();
        gPausedFrame.clear();
        gQueue.clear();
        for (auto& ev : gSong.events) {
            if (ev.sound) {
                schedule_sound_delete(ev.sound);
                ev.sound = nullptr;
            }
        }
        gSong = Song{};
        for (auto& av : gActiveVoices) {
            if (av.sound) {
                ma_sound_stop(av.sound);
                schedule_sound_delete(av.sound);
                av.sound = nullptr;
            }
        }
        gActiveVoices.clear();
        gPendingStops.clear();
        // NOTA: la destrucción real ocurre en gm_audio_transport_tick()
        ma_engine_uninit(&gEngine);
        gEngineIniciado = false;
        return 1.0;
    }




    ////////////////////////////////////////////////////////////////////////////////////////
    // REPRODUCCION BASICA
    ////////////////////////////////////////////////////////////////////////////////////////

    // Crea y reproduce un sonido desde archivo
    __declspec(dllexport) double gm_audio_play(const char* path) {
        if (!gEngineIniciado || path == nullptr) return 0.0;
        std::lock_guard<std::mutex> lock(gMutex);
        ma_sound* s = new ma_sound();
        ma_result res = ma_sound_init_from_file(&gEngine, path, 0, NULL, NULL, s);
        if (res != MA_SUCCESS) {
            delete s;
            return 0.0;
        }
        ma_sound_start(s);
        int id = makeId();
        gSounds[id] = s;
        gPausedFrame.erase(id);
        return (double)id;
    }


    // Detiene y destruye un sonido existente por ID
    __declspec(dllexport) double gm_audio_stop(double idd) {
        int id = (int)idd;
        std::lock_guard<std::mutex> lock(gMutex);
        auto it = gSounds.find(id);
        if (it == gSounds.end()) return 0.0;
        ma_sound_stop(it->second);
        schedule_sound_delete(it->second);
        gSounds.erase(it);
        gPausedFrame.erase(id);
        return 1.0;
    }


    // Pausa guarda la posicion en frames y para el sonido
    // Devuelve 1 si ok, 0 si el ID no existe o get_cursor falla
    __declspec(dllexport) double gm_audio_pause(double idd) {
        int id = (int)idd;
        std::lock_guard<std::mutex> lock(gMutex);
        auto it = gSounds.find(id);
        if (it == gSounds.end()) return 0.0;
        ma_uint64 frame = 0;
        if (ma_sound_get_cursor_in_pcm_frames(it->second, &frame) != MA_SUCCESS)
            return 0.0;
        gPausedFrame[id] = frame;
        ma_sound_stop(it->second);
        return 1.0;
    }


    // Resume si hay una posicion almacenada, hace seek y arranca
    // Devuelve 1 si arranca, 0 si algo falla o no existe el ID
    __declspec(dllexport) double gm_audio_resume(double idd) {
        int id = (int)idd;
        std::lock_guard<std::mutex> lock(gMutex);
        auto it = gSounds.find(id);
        if (it == gSounds.end()) return 0.0;
        ma_uint64 frame = 0;
        auto itp = gPausedFrame.find(id);
        if (itp != gPausedFrame.end()) frame = itp->second;
        if (frame > 0) {
            ma_sound_seek_to_pcm_frame(it->second, frame);
        }
        if (ma_sound_start(it->second) != MA_SUCCESS)
            return 0.0;
        gPausedFrame.erase(id);
        return 1.0;
    }


    // Volumen de 0 a 1
    __declspec(dllexport) double gm_audio_set_volume(double idd, double v) {
        int id = (int)idd;
        float vol = (float)v;
        if (vol < 0.f) vol = 0.f;
        if (vol > 1.f) vol = 1.f;
        std::lock_guard<std::mutex> lock(gMutex);
        auto it = gSounds.find(id);
        if (it == gSounds.end()) return 0.0;
        ma_sound_set_volume(it->second, vol);
        return 1.0;
    }


    // Loop on/off
    __declspec(dllexport) double gm_audio_set_loop(double idd, double flag) {
        int id = (int)idd;
        ma_bool32 loop = (flag != 0.0) ? MA_TRUE : MA_FALSE;
        std::lock_guard<std::mutex> lock(gMutex);
        auto it = gSounds.find(id);
        if (it == gSounds.end()) return 0.0;
        ma_sound_set_looping(it->second, loop);
        return 1.0;
    }





    ////////////////////////////////////////////////////////////////////////////////////////
    // TRANSPORT
    ////////////////////////////////////////////////////////////////////////////////////////

    // Pone el transport en marcha. Si ya estaba en play, no reinicia baseBeat
    __declspec(dllexport) double gm_audio_transport_play() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gEngineIniciado) return 0.0;
        if (!gTransport.playing.load()) {
            gTransport.startTime = std::chrono::high_resolution_clock::now();
            gTransport.playing.store(true);
        }
        return 1.0;
    }


    // Pausa el transport acumulando el beat actual en baseBeat
    __declspec(dllexport) double gm_audio_transport_pause() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gEngineIniciado) return 0.0;
        if (gTransport.playing.load()) {
            gTransport.baseBeat = transport_get_beat_unlocked();
            gTransport.playing.store(false);
        }
        return 1.0;
    }


    // Para el transport y resetea el contador a 0.
    __declspec(dllexport) double gm_audio_transport_stop() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gEngineIniciado) return 0.0;

        // Para el transport y resetea el beat base a 0
        gTransport.playing.store(false);
        gTransport.baseBeat = 0.0;

        // Limpiar cola de lanzamientos cuantizados
        gQueue.clear();

        // Parar y agenda borrado de voces pendientes
        for (auto& ps : gPendingStops) {
            if (ps.voice) {
                ma_sound_stop(ps.voice);
                schedule_sound_delete(ps.voice);
                ps.voice = nullptr;
            }
        }
        gPendingStops.clear();

        // Parar y agenda borrado de voces activas
        for (auto& av : gActiveVoices) {
            if (av.sound) {
                ma_sound_stop(av.sound);
                schedule_sound_delete(av.sound);
                av.sound = nullptr;
            }
        }
        gActiveVoices.clear();

        // Reiniciar la canción: empezar desde el principio
        if (gSong.loaded) {
            gSong.startBeat = 0.0;
            for (auto& ev : gSong.events) {
                ev.active = true;
                // Mantener offsetBeat para respetar la posición del evento en el patrón
                ev.nextBeat = ev.offsetBeat;
            }
        }

        return 1.0;
    }




    // Cambia el BPM manteniendo la continuidad del beat
    __declspec(dllexport) double gm_audio_set_tempo(double bpm) {
        std::lock_guard<std::mutex> lock(gMutex);
        if (bpm <= 0.0) return 0.0;

        // Captura el beat actual con el bpm anterior
        double current = transport_get_beat_unlocked();

        // Aplica el nuevo bpm
        gTransport.bpm.store(bpm);

        // Si esta en play, reancla el reloj al instante actual manteniendo el beat
        if (gTransport.playing.load()) {
            gTransport.baseBeat = current;
            gTransport.startTime = std::chrono::high_resolution_clock::now();
        }
        else {
            // En pausa: conserva el beat actual
            gTransport.baseBeat = current;
        }
        return 1.0;
    }



    // Devuelve el beat actual como double
    __declspec(dllexport) double gm_audio_get_beat_position() {
        std::lock_guard<std::mutex> lock(gMutex);
        return transport_get_beat_unlocked();
    }






    ////////////////////////////////////////////////////////////////////////////////////////
    // Preset JSON
    ////////////////////////////////////////////////////////////////////////////////////////

    // Lee un archivo JSON y, si tiene bpm, actualiza el transport
    // Mantiene continuidad del beat en play, resetea a 0 en stop/pausa inicial.
    __declspec(dllexport) double gm_audio_load_preset_file(const char* path) {
        if (!gEngineIniciado || path == nullptr) return 0.0;
        std::lock_guard<std::mutex> lock(gMutex);
        std::string txt;
        if (!readTextFile(path, txt)) return 0.0;
        double bpm = gTransport.bpm.load();
        double parsed = bpm;
        if (json_extract_bpm(txt, parsed) && parsed > 0.0) {
            bpm = parsed;
        }

        // Aplica bpm con la misma logica que set_tempo
        double current = transport_get_beat_unlocked();
        gTransport.bpm.store(bpm);
        if (gTransport.playing.load()) {
            gTransport.baseBeat = current;
            gTransport.startTime = std::chrono::high_resolution_clock::now();
        }
        else {
            // Si estaba parado/pausado, empezamos desde 0 para reflejar preset nuevo
            gTransport.baseBeat = 0.0;
        }
        return 1.0;
    }




    ////////////////////////////////////////////////////////////////////////////////////////
    // Lanzamiento cuantizado al beat
    ////////////////////////////////////////////////////////////////////////////////////////

    // Prepara un sonido y lo programa para el proximo multiplo de quant beats
    // 1 negras, 0.5 corcheas, 0.25 semicorcheas...
    __declspec(dllexport) double gm_audio_play_on_beat(const char* path, double quant_beats) {
        if (!gEngineIniciado || path == nullptr) return 0.0;
        if (quant_beats <= 0.0) quant_beats = 1.0;
        std::lock_guard<std::mutex> lock(gMutex);
        ma_sound* s = new ma_sound();
        if (ma_sound_init_from_file(&gEngine, path, 0, NULL, NULL, s) != MA_SUCCESS) {
            delete s;
            return 0.0;
        }
        int id = makeId();
        gSounds[id] = s;
        gPausedFrame.erase(id);

        // Calcula el siguiente grid en beats
        const double nowBeat = transport_get_beat_unlocked();
        const double q = quant_beats;
        const double next = std::ceil(nowBeat / q) * q;

        // Encola el lanzamiento
        gQueue.push_back({ id, next });
        return (double)id;
    }





    // Tick del transport: revisa la cola y dispara los sonidos cuyo targetBeat llegue
    __declspec(dllexport) double gm_audio_transport_tick() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gEngineIniciado) return 0.0;
        if (!gTransport.playing.load()) return 1.0;
        const double beat = transport_get_beat_unlocked();

        for (auto it = gQueue.begin(); it != gQueue.end();) {
            if (beat + 1e-6 >= it->targetBeat) {
                auto itS = gSounds.find(it->id);
                if (itS != gSounds.end()) {
                    ma_sound_seek_to_pcm_frame(itS->second, 0);
                    ma_sound_start(itS->second);
                }
                it = gQueue.erase(it);
            }
            else {
                ++it;
            }
        }

        if (gSong.loaded) {
            const double songLenBeats = (double)gSong.beatsPerBar * (double)gSong.bars;

            for (auto it = gPendingStops.begin(); it != gPendingStops.end();) {
                if (beat + 1e-6 >= it->endBeat) {
                    if (it->voice) {
                        ma_sound_stop(it->voice);
                        schedule_sound_delete(it->voice);
                        for (auto vit = gActiveVoices.begin(); vit != gActiveVoices.end();) {
                            if (vit->sound == it->voice) vit = gActiveVoices.erase(vit);
                            else ++vit;
                        }
                        it->voice = nullptr;
                    }
                    it = gPendingStops.erase(it);
                }
                else ++it;
            }

            for (auto& ev : gSong.events) {
                if (!ev.active) continue;

                // Mientras estemos alcanzando instantes programados, dispara y programa el siguiente ciclo
                while (beat + 1e-6 >= ev.nextBeat) {
                    // Tocar
                    if (ev.sound) {
                        ma_sound_seek_to_pcm_frame(ev.sound, 0);
                        ma_sound_start(ev.sound);
                    }
                    else {
                        size_t pnote = ev.path.find("|NOTE:");
                        if (pnote != std::string::npos) {
                            std::string filePart = ev.path.substr(0, pnote);
                            std::string notePart;
                            double baseNote = 60.0;
                            double tuningHz = 440.0;
                            size_t pbase = ev.path.find("|BASE:", pnote);
                            size_t ptun = ev.path.find("|TUN:", pnote);
                            if (pbase != std::string::npos) {
                                notePart = ev.path.substr(pnote + 6, pbase - (pnote + 6));
                                if (ptun != std::string::npos) {
                                    baseNote = std::stod(ev.path.substr(pbase + 6, ptun - (pbase + 6)));
                                    tuningHz = std::stod(ev.path.substr(ptun + 5));
                                }
                                else {
                                    baseNote = std::stod(ev.path.substr(pbase + 6));
                                }
                            }
                            else {
                                notePart = ev.path.substr(pnote + 6);
                            }
                            double vel = ev.vel;
                            int midi = note_name_to_midi(notePart);
                            if (midi >= 0) {
                                double delta = (double)midi - baseNote;
                                double pitch = pitch_from_semitones(delta, 0.0);
                                ma_sound* v = new ma_sound();
                                if (ma_sound_init_from_file(&gEngine, filePart.c_str(), 0, NULL, NULL, v) == MA_SUCCESS) {
                                    ma_sound_set_volume(v, (float)vel);
                                    ma_sound_set_pitch(v, (float)pitch);
                                    ma_sound_start(v);
                                    gActiveVoices.push_back(ActiveVoice{ v, makeId() });
                                    if (ev.dur > 1e-9) {
                                        double voiceEndBeat = beat + ev.dur;
                                        gPendingStops.push_back(PendingStop{ v, voiceEndBeat });
                                    }
                                }
                                else {
                                    delete v;
                                }
                            }
                        }
                    }

                    // Programar proximo
                    ev.nextBeat += gSong.beatsPerBar;

                    // Si no hay loop y nos pasamos del final de la cancion, desactivamos este evento
                    if (!gSong.loop && (ev.nextBeat - gSong.startBeat) >= songLenBeats + 1e-6) {
                        ev.active = false;
                        break;
                    }
                }
            }
        }

        // Procesar destrucción diferida de ma_sound
        if (!gPendingDelete.empty()) {
            for (ma_sound* s : gPendingDelete) {
                if (s) {
                    ma_sound_stop(s);
                    ma_sound_uninit(s);
                    delete s;
                }
            }
            gPendingDelete.clear();
        }

        return 1.0;
    }





    // Carga una cancion desde JSON (ruta en disco). Pre-carga los wav como ma_sound.
    __declspec(dllexport) double gm_audio_song_load_file(const char* pathJson) {
        if (!gEngineIniciado || pathJson == nullptr) return 0.0;
        std::lock_guard<std::mutex> lock(gMutex);
        std::string txt;
        if (!readTextFile(pathJson, txt)) return 0.0;
        std::string baseDir = path_dirname(pathJson);


        // Parametros por defecto
        int beatsPerBar = 4;
        int bars = 1;
        bool loop = true;
        json_extract_int(txt, "beatsPerBar", beatsPerBar);
        json_extract_int(txt, "bars", bars);
        json_extract_bool(txt, "loop", loop);

        double parsedBpm;
        if (json_extract_bpm(txt, parsedBpm) && parsedBpm > 0.0) {
            double current = transport_get_beat_unlocked();
            gTransport.bpm.store(parsedBpm);
            if (gTransport.playing.load()) {
                gTransport.baseBeat = current;
                gTransport.startTime = std::chrono::high_resolution_clock::now();
            }
            else {
                gTransport.baseBeat = 0.0;
            }
        }

        std::vector<SongEvent> evs;
        if (!json_extract_events(txt, evs)) return 0.0;

        // Liberar cancion previa
        for (auto& ev : gSong.events) {
            if (ev.sound) {
                schedule_sound_delete(ev.sound);
                ev.sound = nullptr;
            }
        }
        gSong = Song{};

        std::regex reInstr(R"("instrument"\s*:\s*\{\s*\"file\"\s*:\s*\"([^\"]+)\"(?:\s*,\s*\"baseNote\"\s*:\s*([-]?\d+))?(?:\s*,\s*\"tuningHz\"\s*:\s*([0-9.]+))?)", std::regex::icase);
        std::smatch mInstr;
        std::string globalInstrFile;
        int globalBaseNote = 60;
        double globalTuningHz = 440.0;
        if (std::regex_search(txt, mInstr, reInstr)) {
            if (mInstr.size() >= 2 && mInstr[1].matched) globalInstrFile = mInstr[1].str();
            if (mInstr.size() >= 3 && mInstr[2].matched) globalBaseNote = std::stoi(mInstr[2].str());
            if (mInstr.size() >= 4 && mInstr[3].matched) globalTuningHz = std::stod(mInstr[3].str());
        }

        std::vector<SongEvent> loadedEvents;
        loadedEvents.reserve(evs.size());

        for (auto& ev : evs) {
            if (ev.path.rfind("NOTE:", 0) == 0) {
                std::string noteTail = ev.path.substr(5);
                std::string noteStr;
                double vel = 1.0;
                size_t pvel = noteTail.find("|vel=");
                if (pvel != std::string::npos) {
                    noteStr = noteTail.substr(0, pvel);
                    try { vel = std::stod(noteTail.substr(pvel + 5)); }
                    catch (...) { vel = 1.0; }
                }
                else {
                    noteStr = noteTail;
                }
                SongEvent sev;
                sev.sound = nullptr;
                sev.offsetBeat = ev.offsetBeat;
                sev.active = true;
                sev.dur = ev.dur;
                sev.vel = (float)vel;
                if (globalInstrFile.empty()) {
                    for (auto& le : loadedEvents) {
                        if (le.sound) { schedule_sound_delete(le.sound); le.sound = nullptr; }
                    }
                    return 0.0;
                }
                std::string instrFullPath = path_join(baseDir, globalInstrFile);
                std::ostringstream meta;
                meta << instrFullPath << "|NOTE:" << noteStr << "|BASE:" << globalBaseNote << "|TUN:" << globalTuningHz;
                sev.path = meta.str();
                loadedEvents.push_back(sev);
            }
            else {
                ma_sound* s = new ma_sound();
                std::string fullPath = path_join(baseDir, ev.path);
                if (ma_sound_init_from_file(&gEngine, fullPath.c_str(), 0, NULL, NULL, s) != MA_SUCCESS) {
                    delete s;
                    for (auto& le : loadedEvents) {
                        if (le.sound) { schedule_sound_delete(le.sound); le.sound = nullptr; }
                    }
                    return 0.0;
                }
                SongEvent sev;
                sev.path = fullPath;
                sev.sound = s;
                sev.offsetBeat = ev.offsetBeat;
                sev.nextBeat = 0.0;
                sev.dur = ev.dur;
                sev.vel = ev.vel;
                sev.active = true;
                loadedEvents.push_back(sev);
            }
        }

        gSong.loaded = true;
        gSong.loop = loop;
        gSong.beatsPerBar = (beatsPerBar > 0) ? beatsPerBar : 4;
        gSong.bars = (bars > 0) ? bars : 1;
        gSong.events = std::move(loadedEvents);
        return 1.0;
    }

    __declspec(dllexport) double gm_audio_song_play() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gEngineIniciado || !gSong.loaded) return 0.0;
        if (!gTransport.playing.load()) {
            gTransport.startTime = std::chrono::high_resolution_clock::now();
            gTransport.playing.store(true);
        }
        const double nowBeat = transport_get_beat_unlocked();
        const double start = std::ceil(nowBeat);
        gSong.startBeat = start;
        for (auto& ev : gSong.events) {
            ev.active = true;
            ev.nextBeat = gSong.startBeat + ev.offsetBeat;
        }
        return 1.0;
    }




    // Para o limpia el estado de la cancion
    __declspec(dllexport) double gm_audio_song_stop() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gSong.loaded) return 1.0;
        for (auto& ev : gSong.events) {
            if (ev.sound) ma_sound_stop(ev.sound);
            ev.active = false;
            ev.nextBeat = 0.0;
        }
        for (auto& ps : gPendingStops) {
            if (ps.voice) {
                ma_sound_stop(ps.voice);
                schedule_sound_delete(ps.voice);
                ps.voice = nullptr;
            }
        }
        gPendingStops.clear();
        for (auto& av : gActiveVoices) {
            if (av.sound) {
                ma_sound_stop(av.sound);
                schedule_sound_delete(av.sound);
                av.sound = nullptr;
            }
        }
        gActiveVoices.clear();
        return 1.0;
    }




    // Cambia el loop de la cancion
    __declspec(dllexport) double gm_audio_song_set_loop(double flag) {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gSong.loaded) return 0.0;
        gSong.loop = (flag != 0.0);
        return 1.0;
    }

} // extern "C"