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
// indica si el engine esta inicializado
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

        // Libera todos los sonidos vivos
        for (auto& kv : gSounds) {
            ma_sound_uninit(kv.second);
            delete kv.second;
        }
        gSounds.clear();
        gPausedFrame.clear();
        gQueue.clear();

        ma_engine_uninit(&gEngine);
        gEngineIniciado = false;
        return 1.0;
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    // REPRODUCCION BASICA
    ////////////////////////////////////////////////////////////////////////////////////////

    // Crea y reproduce un sonido desde archivo. Devuelve el ID > 0 o 0 si falla.
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

        // Recorremos la cola y lanzamos los vencidos
        for (auto it = gQueue.begin(); it != gQueue.end(); ) {
            if (beat + 1e-6 >= it->targetBeat) {
                auto itS = gSounds.find(it->id);
                if (itS != gSounds.end()) {
                    ma_sound_seek_to_pcm_frame(itS->second, 0); // por si acaso
                    ma_sound_start(itS->second);
                }
                it = gQueue.erase(it); // borra y avanza
            }
            else {
                ++it;
            }
        }
        return 1.0;
    }

} // extern C