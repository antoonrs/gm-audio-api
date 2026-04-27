function import_song_from_json(path_opt) {

    var ctrl = instance_find(obj_control_variables, 0)
    if (ctrl == noone) return ""

    var path = ""

    // RUTA
    if (is_undefined(path_opt)) {
        var chosen = get_open_filename("JSON files (*.json)|*.json", "")
        if (chosen == "" || chosen == undefined) return ""
        path = string(chosen)
    } else {
        if (!is_string(path_opt) || string(path_opt) == "") {
            var chosen2 = get_open_filename("JSON files (*.json)|*.json", "")
            if (chosen2 == "" || chosen2 == undefined) return ""
            path = string(chosen2)
        } else {
            path = string(path_opt)
        }
    }

    if (!file_exists(path)) {
        var slash = max(string_pos("\\", path), string_pos("/", path))
        var basename = (slash > 0) ? string_copy(path, slash + 1, 999) : path
        var alt = working_directory + basename

        if (file_exists(alt)) path = alt
        else return ""
    }

    var fh = file_text_open_read(path)
    if (fh == -1) return ""

    var json_text = ""
    while (!file_text_eof(fh)) {
        json_text += file_text_read_string(fh)
        file_text_readln(fh)
    }
    file_text_close(fh)

    var data = json_parse(json_text)
    if (!is_struct(data)) return ""

    if (variable_struct_exists(data,"bpm")) ctrl.bpm = data.bpm
    if (variable_struct_exists(data,"beatsPerBar")) ctrl.beatsPerBar = data.beatsPerBar
    if (variable_struct_exists(data,"bars")) ctrl.bars = data.bars
    if (variable_struct_exists(data,"loop")) ctrl.loop_song = data.loop

    ctrl.instruments = []

    if (variable_struct_exists(data,"instruments") && is_array(data.instruments)) {
        for (var i = 0; i < array_length(data.instruments); i++) {
            var ins = data.instruments[i]

            ctrl.instruments[i] = {
                name : variable_struct_exists(ins,"name") ? ins.name : "",
                file : variable_struct_exists(ins,"file") ? ins.file : "",
                baseNote : variable_struct_exists(ins,"baseNote") ? ins.baseNote : 60,
                tuningHz : variable_struct_exists(ins,"tuningHz") ? ins.tuningHz : 440
            }
        }
    }

    ctrl.numinstruments = array_length(ctrl.instruments)

    ctrl.events = []

    if (variable_struct_exists(data,"events") && is_array(data.events)) {
        for (var j = 0; j < array_length(data.events); j++) {
            var e = data.events[j]

            ctrl.events[j] = {
                note : variable_struct_exists(e,"note") ? string(e.note) : "",
                beat : variable_struct_exists(e,"beat") ? real(e.beat) : 0,
                dur  : variable_struct_exists(e,"dur") ? real(e.dur) : 0,
                vel  : variable_struct_exists(e,"vel") ? real(e.vel) : 1,
                bus  : variable_struct_exists(e,"bus") ? real(e.bus) : 0,
                instr: variable_struct_exists(e,"instr") ? string(e.instr) : ""
            }
        }
    }

    ctrl.savelocation = path

    var mm = instance_find(obj_main_menu,0)
    if (mm != noone) {
        mm.alarm[0] = 1
        mm.numinstruments = array_length(ctrl.instruments)
    }

    return path
}