function export_song_to_json(path_opt) {
    var ctrl = instance_find(obj_control_variables, 0)
    if (ctrl == noone) {
        show_debug_message("ERROR EN EXPORT, NO SE ENCUENTRA EL OBJ DE VARIABLES");
        return ""
    }

    var target = ""

    if (is_undefined(path_opt)) {
        // SAVE AS
        var chosen = get_save_filename("JSON files (*.json)|*.json", "song_export.json");
        if (chosen == "" || chosen == undefined) {
            show_debug_message("Se cancelo la seleccion")
            return ""
        }
        target = string(chosen)
    }
    else {
        // SAVE
        if (!is_string(path_opt) || string(path_opt) == "") {
            // pedir ruta
            var chosen2 = get_save_filename("JSON files (*.json)|*.json", "song_export.json")
            if (chosen2 == "" || chosen2 == undefined) {
                show_debug_message("Se cancelo la seleccion")
                return ""
            }
            target = string(chosen2)
        } else {
            target = string(path_opt)
        }
    }

    show_debug_message("Ruta solicitada: " + target)

    /////////// CONSTRUIR EL STRUCT BASE /////////////////////
	
    if (!is_array(ctrl.instruments)) ctrl.instruments = []
    if (!is_array(ctrl.events)) ctrl.events = []

    var data = {
        bpm : ctrl.bpm,
        beatsPerBar : ctrl.beatsPerBar,
        bars : ctrl.bars,
        loop : ctrl.loop_song,
        instruments : ctrl.instruments,
        events : ctrl.events
    };

    ////////////// GENERAR JSON REAL ////////////////////
    var j = json_stringify(data, true)

    show_debug_message("JSON length = " + string(string_length(j)))

    //////////////////////////////////////////
	
    var fh = file_text_open_write(target)
    if (fh != -1) {
        file_text_write_string(fh, j)
        file_text_close(fh)
        show_debug_message("Escrito correctamente en ruta solicitada")
        return target
    }

    // Si falla, intentamos fallback a working_directory
    show_debug_message("Fallo en ruta solicitada, intentando fallback...")

    var slash = max(string_pos("\\", target), string_pos("/", target))
    var basename = (slash > 0) ? string_copy(target, slash + 1, 999) : target

    var fallback = working_directory + basename

    var fh2 = file_text_open_write(fallback)
    if (fh2 != -1) {
        file_text_write_string(fh2, j)
        file_text_close(fh2)
        show_debug_message("Fallback OK: " + fallback)
        return fallback
    }

    // fallo total
    show_debug_message("ERROR final: no pudo escribirse en ninguna ruta");
    return "";
}