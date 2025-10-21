#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include <unordered_map>
#include <mutex>
#include <atomic>
#include <string>

static ma_engine gEngine;
static bool gInit = false;

static std::unordered_map<int, ma_sound*> gSounds;
static std::unordered_map<int, ma_uint64> gPausedFrame;
static std::mutex gMutex;
static std::atomic<int> gNextId{ 1 };

static inline int makeId() { return gNextId.fetch_add(1); }

extern "C" {

    __declspec(dllexport) double gm_audio_init() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (gInit) return 1.0;

        ma_result res = ma_engine_init(NULL, &gEngine);
        if (res == MA_SUCCESS) {
            gInit = true;
            return 1.0;
        }
        return 0.0;
    }

    __declspec(dllexport) double gm_audio_shutdown() {
        std::lock_guard<std::mutex> lock(gMutex);
        if (!gInit) return 1.0;

        for (auto& kv : gSounds) {
            ma_sound_uninit(kv.second);
            delete kv.second;
        }
        gSounds.clear();
        gPausedFrame.clear();

        ma_engine_uninit(&gEngine);
        gInit = false;
        return 1.0;
    }

    __declspec(dllexport) double gm_audio_play(const char* path) {
        if (!gInit || path == nullptr) return 0.0;
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

    __declspec(dllexport) double gm_audio_set_loop(double idd, double flag) {
        int id = (int)idd;
        ma_bool32 loop = (flag != 0.0) ? MA_TRUE : MA_FALSE;

        std::lock_guard<std::mutex> lock(gMutex);
        auto it = gSounds.find(id);
        if (it == gSounds.end()) return 0.0;

        ma_sound_set_looping(it->second, loop);
        return 1.0;
    }

}