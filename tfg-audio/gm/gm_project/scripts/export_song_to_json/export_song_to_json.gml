function export_song_to_json(path_opt) {

    var ctrl = instance_find(obj_control_variables, 0)
    if (ctrl == noone) return ""

    var target = ""

    // RUTA
    if (is_undefined(path_opt)) {
        var chosen = get_save_filename("JSON files (*.json)|*.json", "song_export.json")
        if (chosen == "" || chosen == undefined) return ""
        target = string(chosen)
    } else {
        if (!is_string(path_opt) || string(path_opt) == "") {
            var chosen2 = get_save_filename("JSON files (*.json)|*.json", "song_export.json")
            if (chosen2 == "" || chosen2 == undefined) return ""
            target = string(chosen2)
        } else {
            target = string(path_opt)
        }
    }

    // SEGURIDAD
    if (!is_array(ctrl.instruments)) ctrl.instruments = []
    if (!is_array(ctrl.events)) ctrl.events = []

    var events_out = array_create(0)

    for (var i = 0; i < array_length(ctrl.events); i++) {
        var e = ctrl.events[i]

        events_out[i] = {
            note : string(e.note),
            beat : real(e.beat),
            dur  : real(e.dur),
            vel  : real(e.vel),
            bus  : real(e.bus),
            instr: string(e.instr)
        }
    }

    var data = {
        bpm : real(ctrl.bpm),
        beatsPerBar : real(ctrl.beatsPerBar),
        bars : real(ctrl.bars),
        loop : ctrl.loop_song,
        instruments : ctrl.instruments,
        events : events_out
    }

    var json = json_stringify(data, true)

    var fh = file_text_open_write(target)
    if (fh != -1) {
        file_text_write_string(fh, json)
        file_text_close(fh)
        return target
    }

    var slash = max(string_pos("\\", target), string_pos("/", target))
    var basename = (slash > 0) ? string_copy(target, slash + 1, 999) : target
    var fallback = working_directory + basename

    var fh2 = file_text_open_write(fallback)
    if (fh2 != -1) {
        file_text_write_string(fh2, json)
        file_text_close(fh2)
        return fallback
    }

    return ""
}