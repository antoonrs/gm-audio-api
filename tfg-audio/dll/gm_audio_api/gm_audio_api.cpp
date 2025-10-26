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
struct PendingLaunch {
    int id; // id del sonido ya creado
    double targetBeat; // beat absoluto donde debe iniciar
};
static std::vector<PendingLaunch> gQueue;

////////////////////////////////////////////////////////////////////////////////////////
// UTILDADES DE ARCHIVO Y PARSER JSON
////////////////////////////////////////////////////////////////////////////////////////

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


////////////////////////////////////////////////////////////////////////////////////////
// SECUENCIADOR DE CANCION
////////////////////////////////////////////////////////////////////////////////////////
struct SongEvent {
    std::string path; // ruta del wav
    ma_sound* sound = nullptr;
    double offsetBeat = 0.0; // beat dentro del compás
    double nextBeat = 0.0; // poximo instante absoluto (en beats del transport)
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

    const std::regex reItem(
        "\\{\\s*\"file\"\\s*:\\s*\"([^\"]+)\"\\s*,\\s*\"beat\"\\s*:\\s*([-+]?\\d*\\.?\\d+)\\s*\\}"
    );

    auto it = std::sregex_iterator(txt.begin(), txt.end(), reItem);
    auto end = std::sregex_iterator();

    for (; it != end; ++it) {
        SongEvent ev;
        ev.path = (*it)[1].str();
        ev.offsetBeat = std::stod((*it)[2].str());
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
            ma_sound_uninit(kv.second);
            delete kv.second;
        }
        gSounds.clear();
        gPausedFrame.clear();
        gQueue.clear();

        for (auto& ev : gSong.events) {
            if (ev.sound) {
                ma_sound_uninit(ev.sound);
                delete ev.sound;
                ev.sound = nullptr;
            }
        }
        gSong = Song{};

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
        ma_sound_uninit(it->second);
        delete it->second;
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
        gTransport.playing.store(false);
        gTransport.baseBeat = 0.0;
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

            for (auto& ev : gSong.events) {
                if (!ev.active) continue;

                // Mientras estemos alcanzando instantes programados, dispara y programa el siguiente ciclo
                while (beat + 1e-6 >= ev.nextBeat) {
                    // Tocar
                    if (ev.sound) {
                        ma_sound_seek_to_pcm_frame(ev.sound, 0);
                        ma_sound_start(ev.sound);
                    }

                    // Programar próximo
                    ev.nextBeat += gSong.beatsPerBar;

                    // Si no hay loop y nos pasamos del final de la canción, desactivamos este evento
                    if (!gSong.loop && (ev.nextBeat - gSong.startBeat) >= songLenBeats + 1e-6) {
                        ev.active = false;
                        break;
                    }
                }
            }
        }

        return 1.0;
    }




    // Carga una canción desde JSON (ruta en disco). Pre-carga los wav como ma_sound.
    __declspec(dllexport) double gm_audio_song_load_file(const char* pathJson) {
        if (!gEngineIniciado || pathJson == nullptr) return 0.0;
        std::lock_guard<std::mutex> lock(gMutex);

        std::string txt;
        if (!readTextFile(pathJson, txt)) return 0.0;

        std::string baseDir = path_dirname(pathJson);


        // Parámetros por defecto
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

        // Liberar canción previa
        for (auto& ev : gSong.events) {
            if (ev.sound) {
                ma_sound_uninit(ev.sound);
                delete ev.sound;
            }
        }
        gSong = Song{};

        for (auto& ev : evs) {
            ma_sound* s = new ma_sound();

            std::string fullPath = path_join(baseDir, ev.path);

            if (ma_sound_init_from_file(&gEngine, fullPath.c_str(), 0, NULL, NULL, s) != MA_SUCCESS) {
                delete s;
                for (auto& ev2 : evs) {
                    if (ev2.sound) { ma_sound_uninit(ev2.sound); delete ev2.sound; }
                }
                return 0.0;
            }
            ev.sound = s;
            ev.path = fullPath;
        }

        gSong.loaded = true;
        gSong.loop = loop;
        gSong.beatsPerBar = (beatsPerBar > 0) ? beatsPerBar : 4;
        gSong.bars = (bars > 0) ? bars : 1;
        gSong.events = std::move(evs);
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




    // Para o limpia el estado de la canción
    __declspec(dllexport) double gm_audio_song_stop() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gSong.loaded) return 1.0;
        for (auto& ev : gSong.events) {
            if (ev.sound) ma_sound_stop(ev.sound);
            ev.active = false;
            ev.nextBeat = 0.0;
        }
        return 1.0;
    }




    // Cambia el loop de la canción
    __declspec(dllexport) double gm_audio_song_set_loop(double flag) {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gSong.loaded) return 0.0;
        gSong.loop = (flag != 0.0);
        return 1.0;
    }

} // extern C