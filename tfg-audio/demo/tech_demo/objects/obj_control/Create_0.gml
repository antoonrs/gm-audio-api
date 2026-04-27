global.ext = {};

var dll = "dll\\gmaudioapi.dll";
show_debug_message("WD = " + working_directory);
show_debug_message("DLL path = " + (working_directory + dll));
show_debug_message("DLL existe? " + string(file_exists(working_directory + dll)));

global.ext.init       = external_define(dll, "gm_audio_init",                dll_cdecl, ty_real, 0);
global.ext.shutdown   = external_define(dll, "gm_audio_shutdown",            dll_cdecl, ty_real, 0);

global.ext.play       = external_define(dll, "gm_audio_play",                dll_cdecl, ty_real, 1, ty_string);
global.ext.stop       = external_define(dll, "gm_audio_stop",                dll_cdecl, ty_real, 1, ty_real);
global.ext.pauseS     = external_define(dll, "gm_audio_pause",               dll_cdecl, ty_real, 1, ty_real);
global.ext.resumeS    = external_define(dll, "gm_audio_resume",              dll_cdecl, ty_real, 1, ty_real);
global.ext.setvol     = external_define(dll, "gm_audio_set_volume",          dll_cdecl, ty_real, 2, ty_real, ty_real);
global.ext.setloop    = external_define(dll, "gm_audio_set_loop",            dll_cdecl, ty_real, 2, ty_real, ty_real);

global.ext.loadPreset = external_define(dll, "gm_audio_load_preset_file",    dll_cdecl, ty_real, 1, ty_string);
global.ext.tplay      = external_define(dll, "gm_audio_transport_play",      dll_cdecl, ty_real, 0);
global.ext.tpause     = external_define(dll, "gm_audio_transport_pause",     dll_cdecl, ty_real, 0);
global.ext.tstop      = external_define(dll, "gm_audio_transport_stop",      dll_cdecl, ty_real, 0);
global.ext.setTempo   = external_define(dll, "gm_audio_set_tempo",           dll_cdecl, ty_real, 1, ty_real);
global.ext.getBeat    = external_define(dll, "gm_audio_get_beat_position",   dll_cdecl, ty_real, 0);
global.ext.tick       = external_define(dll, "gm_audio_transport_tick",      dll_cdecl, ty_real, 0);
global.ext.playQ      = external_define(dll, "gm_audio_play_on_beat",        dll_cdecl, ty_real, 2, ty_string, ty_real);

global.ext.bus_create   = external_define(dll, "gm_audio_bus_create",       dll_cdecl, ty_real, 0);
global.ext.bus_destroy  = external_define(dll, "gm_audio_bus_destroy",      dll_cdecl, ty_real, 1, ty_real);
global.ext.bus_set_vol  = external_define(dll, "gm_audio_bus_set_volume",   dll_cdecl, ty_real, 2, ty_real, ty_real);
global.ext.bus_set_mute = external_define(dll, "gm_audio_bus_set_mute",     dll_cdecl, ty_real, 2, ty_real, ty_real);
global.ext.assign_bus   = external_define(dll, "gm_audio_assign_to_bus",    dll_cdecl, ty_real, 2, ty_real, ty_real);
global.ext.bus_set_pan  = external_define(dll, "gm_audio_bus_set_pan",      dll_cdecl, ty_real, 2, ty_real, ty_real);

global.ext.songLoad  = external_define(dll, "gm_audio_song_load_file",      dll_cdecl, ty_real, 1, ty_string);
global.ext.songPlay  = external_define(dll, "gm_audio_song_play",           dll_cdecl, ty_real, 0);
global.ext.songStop  = external_define(dll, "gm_audio_song_stop",           dll_cdecl, ty_real, 0);
global.ext.songLoop  = external_define(dll, "gm_audio_song_set_loop",       dll_cdecl, ty_real, 1, ty_real);

global.ext.preview_note = external_define(dll,"gm_audio_preview_note",dll_cdecl,ty_real,3,ty_string,ty_real,ty_real);


res_init = external_call(global.ext.init);
show_debug_message("gm_audio_init return = " + string(res_init));