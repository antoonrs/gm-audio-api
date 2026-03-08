external_call(global.ext.tick);





























/*


if (keyboard_check_pressed(ord("P"))) {
	var sound_id = external_call(
    global.ext.play,
    working_directory + "weefagerCancion.mp3"
	);

    show_debug_message("PLAY id=" + string(sound_id));
}

if (keyboard_check_pressed(ord("O")) && id_sound > 0) {
    external_call(global.ext.stop, id_sound);
    id_sound = 0;
    show_debug_message("STOP");
}

if (keyboard_check_pressed(ord("U")) && id_sound > 0) {
    external_call(global.ext.pauseS, id_sound);
    show_debug_message("PAUSE");
}
if (keyboard_check_pressed(ord("R")) && id_sound > 0) {
    external_call(global.ext.resumeS, id_sound);
    show_debug_message("RESUME");
}
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

if (keyboard_check_pressed(ord("L")) && id_sound > 0) {
    loop_on = 1 - loop_on;
    external_call(global.ext.setloop, id_sound, loop_on);
    show_debug_message("LOOP = " + string(loop_on));
}

if (keyboard_check_pressed(ord("B"))) {
    var q = 1.0;
    var idq = external_call(global.ext.playQ, audio_path, q);
    show_debug_message("PLAY QUANT id=" + string(idq) + " q=" + string(q));
}
*/
/*
if (keyboard_check_pressed(vk_left)){
external_call(global.ext.bus_set_pan, bus_drums, -1)
}
if (keyboard_check_pressed(vk_up)){
external_call(global.ext.bus_set_pan, bus_drums, 0)
}
if (keyboard_check_pressed(vk_right)){
external_call(global.ext.bus_set_pan, bus_drums, 1)
}

if (keyboard_check_pressed(ord("T"))) external_call(global.ext.tplay);
if (keyboard_check_pressed(ord("Y"))) external_call(global.ext.tpause);
if (keyboard_check_pressed(ord("I"))) external_call(global.ext.tstop);

if (keyboard_check_pressed(ord("G"))) external_call(global.ext.setTempo, 190);
if (keyboard_check_pressed(ord("H"))) external_call(global.ext.setTempo, 120);

if (keyboard_check_pressed(vk_f5) && file_exists(preset_path)) {
    external_call(global.ext.tpause);
    external_call(global.ext.loadPreset, preset_path);
    external_call(global.ext.tplay);
    show_debug_message("Preset recargado");
}



if (keyboard_check_pressed(ord("K"))) {
    loop_on = 1 - loop_on;
    external_call(global.ext.songLoop, loop_on);
    show_debug_message("SONG LOOP = " + string(loop_on));
}

if (keyboard_check_pressed(ord("J"))) {
    external_call(global.ext.songStop);
}


if keyboard_check_pressed(ord("1"))
{
    drum_vol = max(0, drum_vol - 0.2)
    external_call(global.ext.bus_set_vol, bus_drums, drum_vol)
    show_debug_message("drum_vol = " + string(drum_vol))
}

if keyboard_check_pressed(ord("2"))
{
    drum_vol = min(1, drum_vol + 0.2)
    external_call(global.ext.bus_set_vol, bus_drums, drum_vol)
    show_debug_message("drum_vol = " + string(drum_vol))
}

if keyboard_check_pressed(ord("M"))
{
    drums_muted = 1 - drums_muted
    external_call(global.ext.bus_set_mute, bus_drums, drums_muted)
    show_debug_message("drums_muted = " + string(drums_muted))
}

if keyboard_check_pressed(ord("P"))
{
    id_sound = external_call(global.ext.play, "drum.wav")
    if id_sound > 0
    {
        external_call(global.ext.assign_bus, id_sound, bus_drums)
        show_debug_message("played dynamic sound id=" + string(id_sound) + " assigned to bus " + string(bus_drums))
    }
    else
    {
        show_debug_message("failed to play dynamic sound")
    }
}
