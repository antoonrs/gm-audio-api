function import_song_from_json(path_opt) {
    // localizar controlador
    var ctrl = instance_find(obj_control_variables, 0)
    if (ctrl == noone) {
        show_message("obj_control_variables no encontrado en la room")
        return ""
    }

    // decidir ruta
    var path = ""
    if (is_undefined(path_opt)) {
        // pedir parametro
        var chosen = get_open_filename("JSON files (*.json)|*.json", "")
        if (chosen == "" || chosen == undefined) {
            show_debug_message("Usuario canceló selección")
            return ""
        }
        path = string(chosen)
    } else {
        // se pasó algo
        if (!is_string(path_opt) || string(path_opt) == "") {
            // cadena vacía -> pedir
            var chosen2 = get_open_filename("JSON files (*.json)|*.json", "")
            if (chosen2 == "" || chosen2 == undefined) {
                show_debug_message("Usuario canceló selección.")
                return ""
            }
            path = string(chosen2)
        } else {
            path = string(path_opt)
        }
    }

    show_debug_message("Ruta solicitada: " + path)

    // si no existe, intentar fallback en working_directory
    if (!file_exists(path)) {
        show_debug_message("Ruta no existe. Intentando fallback en working_directory...")
        var slashpos = max(string_pos("\\", path), string_pos("/", path))
        var basename = (slashpos > 0) ? string_copy(path, slashpos + 1, 999) : path
        var alt = working_directory + basename
        if (file_exists(alt)) {
            show_debug_message("Fallback encontrado: " + alt)
            path = alt
        } else {
            show_message("ERROR IMPORT: archivo no encontrado:\n" + path + "\n(Se intentó también: " + alt + ")")
            return ""
        }
    }

    // Leer fichero
    var fh = file_text_open_read(path)
    if (fh == -1) {
        show_message("ERROR: no se pudo abrir el archivo:\n" + path)
        return ""
    }

    var json_text = ""
    while (!file_text_eof(fh)) {
        json_text += file_text_read_string(fh)
        file_text_readln(fh)
    }
    file_text_close(fh)

    //show_debug_message("Raw JSON = " + string(string_length(json_text)));

    // parse
    var data = json_parse(json_text)
	
	
    if (!is_struct(data)) {
        show_message("ERROR IMPORT: JSON inválido")
        return ""
    }

    // asignar campos
    if (variable_struct_exists(data,"bpm")) ctrl.bpm = data.bpm
    if (variable_struct_exists(data,"beatsPerBar")) ctrl.beatsPerBar = data.beatsPerBar
    if (variable_struct_exists(data,"bars")) ctrl.bars = data.bars
    if (variable_struct_exists(data,"loop")) ctrl.loop_song = data.loop

    // instruments
    ctrl.instruments = []
    var loadedIns = 0
    if (variable_struct_exists(data,"instruments") && is_array(data.instruments)) {
        for (var i = 0; i < array_length(data.instruments); ++i) {
            var ins = data.instruments[i]
            var name = (variable_struct_exists(ins,"name")?ins.name:"")
            var file = (variable_struct_exists(ins,"file")?ins.file:"")
            var baseNote = (variable_struct_exists(ins,"baseNote")?ins.baseNote:60)
            var tuningHz = (variable_struct_exists(ins,"tuningHz")?ins.tuningHz:440)
            ctrl.instruments[i] = { name: name, file: file, baseNote: baseNote, tuningHz: tuningHz }
            show_debug_message("Cargado instrument[" + string(i) + "] = " + string(ctrl.instruments[i]))
            loadedIns++
        }
    } else {
        show_debug_message("No hay instrumentos que cargar")
    }
    ctrl.numinstruments = array_length(ctrl.instruments)

    // events
    ctrl.events = []
    var loadedEv = 0
    if (variable_struct_exists(data,"events") && is_array(data.events)) {
        for (var j = 0; j < array_length(data.events); ++j) {
            var e = data.events[j]
            var note = (variable_struct_exists(e,"note")?e.note:undefined)
            var fileEv = (variable_struct_exists(e,"file")?e.file:undefined)
            var beat = (variable_struct_exists(e,"beat")?e.beat:0.0)
            var dur = (variable_struct_exists(e,"dur")?e.dur:0.0)
            var vel = (variable_struct_exists(e,"vel")?e.vel:1.0)
            var bus = (variable_struct_exists(e,"bus")?e.bus:0)
            var instr = (variable_struct_exists(e,"instr")?e.instr:"")
            ctrl.events[j] = { note: note, file: fileEv, beat: beat, dur: dur, vel: vel, bus: bus, instr: instr }
            show_debug_message("IMPORT -> loaded event[" + string(j) + "] = " + string(ctrl.events[j]))
            loadedEv++
        }
    } else {
        show_debug_message("No hay eventos que cargar")
    }

    // guardar ruta usada
    ctrl.savelocation = path

    // actualizar obj_main_menu si existe
    var mm = instance_find(obj_main_menu,0);
    if (mm != noone) {
        mm.alarm[0] = 1
        mm.numinstruments = array_length(ctrl.instruments)
    }

    //show_message("IMPORTACION CORRECTA. INSTRUMENTOS: " + string(loadedIns) + " , EVENTOS: " + string(loadedEv));
    return path;
}
