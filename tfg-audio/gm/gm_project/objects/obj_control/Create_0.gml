/// Inicializa DLL y funciones básicas
global.ext = {};

var dll = "dll\\gmaudioapi.dll";

show_debug_message("WD=" + working_directory);
show_debug_message("DLL existe? " + string(file_exists(working_directory + dll)));


global.ext.init      = external_define(dll, "gm_audio_init",       dll_cdecl, ty_real, 0);
global.ext.shutdown  = external_define(dll, "gm_audio_shutdown",   dll_cdecl, ty_real, 0);
global.ext.play      = external_define(dll, "gm_audio_play",       dll_cdecl, ty_real, 1, ty_string);
global.ext.stop      = external_define(dll, "gm_audio_stop",       dll_cdecl, ty_real, 1, ty_real);
global.ext.pause     = external_define(dll, "gm_audio_pause",      dll_cdecl, ty_real, 1, ty_real);
global.ext.resume    = external_define(dll, "gm_audio_resume",     dll_cdecl, ty_real, 1, ty_real);
global.ext.setvol    = external_define(dll, "gm_audio_set_volume", dll_cdecl, ty_real, 2, ty_real, ty_real);
global.ext.setloop   = external_define(dll, "gm_audio_set_loop",   dll_cdecl, ty_real, 2, ty_real, ty_real);

var ok = external_call(global.ext.init);
show_debug_message("gm_audio_init = " + string(ok));

id_sound = 0;
vol = 1;
loop_on = 0;

audio_path = working_directory + "test.mp3"