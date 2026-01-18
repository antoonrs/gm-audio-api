panel_w = lerp(panel_w, target_w, panel_bounce);
panel_h = lerp(panel_h, target_h, panel_bounce);

if (!panel_opened) {
    if (abs(panel_w - target_w) < 1 && abs(panel_h - target_h) < 1) {
        panel_w = target_w;
        panel_h = target_h;
        panel_opened = true;
    }
}

if (!panel_opened) exit;

var left   = x;
var top    = y;
var right  = x + panel_w;
var bottom = y + panel_h;

var cur_y = top + field_margin_top;
var field_left  = left  + field_margin_side;
var field_right = right - field_margin_side;

var name_top = cur_y;
var name_bottom = cur_y + field_height;
cur_y = name_bottom + field_sep;

var instr_top = cur_y;
var instr_box_top = instr_top;
var instr_box_bottom = instr_box_top + field_height;

cur_y += array_length(global.instrument_library) * (field_height + 6) + field_sep;

var base_top = cur_y;
var base_bottom = cur_y + field_height;
cur_y = base_bottom + field_sep;

var tuning_top = cur_y;
var tuning_bottom = cur_y + field_height;

// Buttons
var btn_y = bottom - field_margin_side - btn_h;

var cancel_left  = field_left;
var cancel_right = cancel_left + btn_w;

var ok_right = field_right;
var ok_left  = ok_right - btn_w;


if (mouse_check_button_pressed(mb_left)) {
    active_field = -1;
    keyboard_string = "";

    if (point_in_rectangle(mouse_x, mouse_y, field_left, name_top, field_right, name_bottom)) {
        // NAME
        active_field = 0;
        keyboard_string = field_name;
        exit;
    } 
    else if (point_in_rectangle(mouse_x, mouse_y, field_left, tuning_top, field_right, tuning_bottom)) {
        // TUNING
        active_field = 3;
        keyboard_string = field_tuning;
        exit;
    }

    var box_top = instr_top;
    var box_bottom = box_top + field_height;
    var h = field_height;
    var count = min(instrument_dropdown_max, array_length(global.instrument_library));

    if (point_in_rectangle(mouse_x, mouse_y, field_left, box_top, field_right, box_bottom)) {
        instrument_dropdown_open = !instrument_dropdown_open;
        if (instrument_dropdown_open) {
            exit;
        }
    }
    else if (instrument_dropdown_open) {
        var clicked_item = -1;
        for (var i = 0; i < count; i++) {
            var top_i = box_bottom + i * (h + 4);
            var bottom_i = top_i + h;
            if (point_in_rectangle(mouse_x, mouse_y, field_left, top_i, field_right, bottom_i)) {
                clicked_item = i;
                break;
            }
        }

        if (clicked_item != -1) {
            selected_instrument = clicked_item;
            instrument_dropdown_open = false;

            external_call(
                global.ext.play,
                working_directory + global.instrument_library[clicked_item].file
            );

            exit;
        } else {
            instrument_dropdown_open = false;
            exit;
        }
    }

    // Botones: Cancel
    if (point_in_rectangle(mouse_x, mouse_y, cancel_left, btn_y, cancel_right, btn_y + btn_h)) {
        instance_destroy();
        obj_main_menu.pantalla = 0;
        exit;
    }

    // Botones: OK
    if (point_in_rectangle(mouse_x, mouse_y, ok_left, btn_y, ok_right, btn_y + btn_h)) {
		
		var name_exists = false;

	    var list = obj_control_variables.instruments;
	    var countr = array_length(list);

	    for (var i = 0; i < countr; i++) {
	        if (string_lower(list[i].name) == string_lower(field_name)) {
	            name_exists = true;
	            break;
	        }
	    }

	    // Si ya existe no se pulsa
	    if (name_exists) {
	        show_debug_message("Ya existe ese nombre: " + field_name);
	        exit;
	    }
		
        var inst = global.instrument_library[selected_instrument];

        obj_control_variables.add_instrument(
            field_name,
            inst.file,
            inst.base_note,
            field_tuning);

        obj_main_menu.numinstruments++;
        obj_main_menu.pantalla = 0;
        obj_main_menu.alarm[0] = 1;

        instance_destroy();
        exit;
    }
}




if (active_field == 0) {
    field_name = keyboard_string;
}

if (active_field == 3) {
    var s = keyboard_string;
    var filtered = "";
    for (var i = 1; i <= string_length(s); i++) {
        var ch = string_char_at(s, i);
        if (ch >= "0" && ch <= "9") filtered += ch;
    }
    field_tuning = filtered;
    keyboard_string = filtered;
}


hover_ok = point_in_rectangle(mouse_x, mouse_y, ok_left, btn_y, ok_right, btn_y + btn_h) && !instrument_dropdown_open;
hover_cancel = point_in_rectangle(mouse_x, mouse_y, cancel_left, btn_y, cancel_right, btn_y + btn_h) && !instrument_dropdown_open;

var scale_lerp = 0.3;
btn_scale_ok = lerp(btn_scale_ok, hover_ok ? 1.1 : 1.0, scale_lerp);
btn_scale_cancel = lerp(btn_scale_cancel, hover_cancel ? 1.1 : 1.0, scale_lerp);