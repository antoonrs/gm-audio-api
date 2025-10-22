external_call(global.ext.tick);

// P: Play directo (no cuantizado)
if (keyboard_check_pressed(ord("P"))) {
    id_sound = external_call(global.ext.play, audio_path);
    show_debug_message("PLAY id=" + string(id_sound));
}

// O: Stop sonido actual
if (keyboard_check_pressed(ord("O")) && id_sound > 0) {
    external_call(global.ext.stop, id_sound);
    id_sound = 0;
    show_debug_message("STOP");
}

// U/R: Pause/Resume sonido actual
if (keyboard_check_pressed(ord("U")) && id_sound > 0) {
    external_call(global.ext.pauseS, id_sound);
    show_debug_message("PAUSE");
}
if (keyboard_check_pressed(ord("R")) && id_sound > 0) {
    external_call(global.ext.resumeS, id_sound);
    show_debug_message("RESUME");
}

// Flechas: volumen
if (keyboard_check_pressed(vk_right) && id_sound > 0) {
    vol = clamp(vol + 0.1, 0, 1);
    external_call(global.ext.setvol, id_sound, vol);
    show_debug_message("VOL " + string(vol));
}
if (keyboard_check_pressed(vk_left) && id_sound > 0) {
    vol = clamp(vol - 0.1, 0, 1);
    external_call(global.ext.setvol, id_sound, vol);
    show_debug_message("VOL " + string(vol));
}

// L: Loop toggle
if (keyboard_check_pressed(ord("L")) && id_sound > 0) {
    loop_on = 1 - loop_on;
    external_call(global.ext.setloop, id_sound, loop_on);
    show_debug_message("LOOP = " + string(loop_on));
}

// T/Y/I: transport play/pause/stop
if (keyboard_check_pressed(ord("T"))) external_call(global.ext.tplay);
if (keyboard_check_pressed(ord("Y"))) external_call(global.ext.tpause);
if (keyboard_check_pressed(ord("I"))) external_call(global.ext.tstop);

// G/H: cambiar tempo
if (keyboard_check_pressed(ord("G"))) external_call(global.ext.setTempo, 128);
if (keyboard_check_pressed(ord("H"))) external_call(global.ext.setTempo, 100);

// B: play cuantizado al próximo beat (q=1.0 negras, 0.5 corcheas, 0.25 semicorcheas…)
if (keyboard_check_pressed(ord("B"))) {
    var q = 1.0;
    var idq = external_call(global.ext.playQ, audio_path, q);
    show_debug_message("PLAY QUANT id=" + string(idq) + " q=" + string(q));
}

// (Opcional) recarga preset con F5 si lo editas fuera
if (keyboard_check_pressed(vk_f5) && file_exists(preset_path)) {
    external_call(global.ext.tpause);
    external_call(global.ext.loadPreset, preset_path);
    external_call(global.ext.tplay);
    show_debug_message("Preset recargado");
}