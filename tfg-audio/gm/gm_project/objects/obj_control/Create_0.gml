global.ext = {};

var dll = "dll\\gmaudioapi.dll";
show_debug_message("WD = " + working_directory);
show_debug_message("DLL existe? " + string(file_exists(working_directory + dll)));

// Nucleo
global.ext.init       = external_define(dll,"gm_audio_init",             dll_cdecl, ty_real, 0);
global.ext.shutdown   = external_define(dll,"gm_audio_shutdown",         dll_cdecl, ty_real, 0);

// Basico
global.ext.play       = external_define(dll,"gm_audio_play",             dll_cdecl, ty_real, 1, ty_string);
global.ext.stop       = external_define(dll,"gm_audio_stop",             dll_cdecl, ty_real, 1, ty_real);
global.ext.pauseS     = external_define(dll,"gm_audio_pause",            dll_cdecl, ty_real, 1, ty_real);
global.ext.resumeS    = external_define(dll,"gm_audio_resume",           dll_cdecl, ty_real, 1, ty_real);
global.ext.setvol     = external_define(dll,"gm_audio_set_volume",       dll_cdecl, ty_real, 2, ty_real, ty_real);
global.ext.setloop    = external_define(dll,"gm_audio_set_loop",         dll_cdecl, ty_real, 2, ty_real, ty_real);

// Transport + preset + cuantizacio
global.ext.loadPreset = external_define(dll,"gm_audio_load_preset_file", dll_cdecl, ty_real, 1, ty_string);
global.ext.tplay      = external_define(dll,"gm_audio_transport_play",   dll_cdecl, ty_real, 0);
global.ext.tpause     = external_define(dll,"gm_audio_transport_pause",  dll_cdecl, ty_real, 0);
global.ext.tstop      = external_define(dll,"gm_audio_transport_stop",   dll_cdecl, ty_real, 0);
global.ext.setTempo   = external_define(dll,"gm_audio_set_tempo",        dll_cdecl, ty_real, 1, ty_real);
global.ext.getBeat    = external_define(dll,"gm_audio_get_beat_position",dll_cdecl, ty_real, 0);
global.ext.tick       = external_define(dll,"gm_audio_transport_tick",   dll_cdecl, ty_real, 0);
global.ext.playQ      = external_define(dll,"gm_audio_play_on_beat",     dll_cdecl, ty_real, 2, ty_string, ty_real);

// Init
var ok = external_call(global.ext.init);
show_debug_message("gm_audio_init = " + string(ok));

// Rutas de prueba
audio_path = working_directory + "test.mp3";
preset_path = working_directory + "presets\\main.json";

// Estado local
id_sound = 0;
vol = 1;
loop_on = 0;

// Carga preset y arranca transport
if (file_exists(preset_path)) {
    external_call(global.ext.loadPreset, preset_path);
}
external_call(global.ext.tplay);

