hover_index = -1

if (point_in_rectangle(mouse_x, mouse_y, x, y, x + width, y + lengthentrada * numentradas)) {
    
    var local_y = mouse_y - y
    var idx = floor(local_y / lengthentrada)
    
    if (idx >= 0 && idx < numentradas) {
        hover_index = idx
    }
}

var bounce = 0.25
var hover = (hover_index != -1)
if (hover) {
    alphamarcadorarchivo = lerp(alphamarcadorarchivo, 1, bounce)
} else {
    alphamarcadorarchivo = lerp(alphamarcadorarchivo, 0, bounce)
}

if (mouse_check_button_pressed(mb_left)) {
    if (hover_index != -1) {
        switch (hover_index) {
            case 0:
                // New Song
				game_restart()
                break;
            case 1:
                // Open Song
				import_song_from_json()
				instance_destroy()
                break;
            case 2:
                // Import MIDI
                break;
            case 3:
                // Export MIDI
                break;
            case 4:
                // Save
				obj_control_variables.savelocation=export_song_to_json(obj_control_variables.savelocation)
				instance_destroy()
                break;
			case 5:
                // Save as
				export_song_to_json()
				instance_destroy()
                break;
        }
    } else {
		instance_destroy()
		obj_main_menu.pantalla=0
    }
}