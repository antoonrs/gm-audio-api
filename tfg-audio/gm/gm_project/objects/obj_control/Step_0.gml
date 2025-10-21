// P: Play
if (keyboard_check_pressed(ord("P"))) {
    id_sound = external_call(global.ext.play, audio_path);
    show_debug_message("PLAY id=" + string(id_sound));
}

// O: Stop
if (keyboard_check_pressed(ord("O")) && id_sound > 0) {
    external_call(global.ext.stop, id_sound);
    show_debug_message("STOP");
    id_sound = 0;
}

// U: Pause
if (keyboard_check_pressed(ord("U")) && id_sound > 0) {
    external_call(global.ext.pause, id_sound);
    show_debug_message("PAUSE");
}

// R: Resume
if (keyboard_check_pressed(ord("R")) && id_sound > 0) {
    external_call(global.ext.resume, id_sound);
    show_debug_message("RESUME");
}

// + / - : Volumen
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
