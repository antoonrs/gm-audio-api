panel_w = lerp(panel_w, target_w, panel_bounce)
panel_h = lerp(panel_h, target_h, panel_bounce)

if (!panel_opened) {
    if (abs(panel_w - target_w) < 1 && abs(panel_h - target_h) < 1) {
        panel_w = target_w
        panel_h = target_h
        panel_opened = true
    }
}

if (!panel_opened) exit

var left = x
var top = y
var right = x + panel_w
var bottom = y + panel_h

var cur_y = top + field_margin_top
var field_left = left  + field_margin_side
var field_right = right - field_margin_side

var name_top = cur_y
var name_bottom = cur_y + field_height
cur_y = name_bottom + field_sep

var file_top = cur_y
var file_bottom = cur_y + field_height
cur_y = file_bottom + field_sep

var base_top = cur_y
var base_bottom = cur_y + field_height
cur_y = base_bottom + field_sep

var tuning_top = cur_y
var tuning_bottom = cur_y + field_height

// Botones
var btn_y = bottom - field_margin_side - btn_h

var cancel_left = field_left
var cancel_right = cancel_left + btn_w

var ok_right = field_right
var ok_left = ok_right - btn_w

if (mouse_check_button_pressed(mb_left)) {
    active_field = -1
    keyboard_string = ""

    if (point_in_rectangle(mouse_x, mouse_y, field_left, name_top, field_right, name_bottom)) {
        // NAME
        active_field = 0
        keyboard_string = field_name

    } else if (point_in_rectangle(mouse_x, mouse_y, field_left, file_top, field_right, file_bottom)) {
        // FILE
        active_field = 1

        var filtro = "Audio Files|*.mp3;*.wav|All Files|*.*"
        var archivo = get_open_filename(filtro, "")
        if (archivo != "") {
            field_file = archivo
        }

    } else if (point_in_rectangle(mouse_x, mouse_y, field_left, base_top, field_right, base_bottom)) {
        // BASE NOTE
        active_field = 2
        keyboard_string = field_base_note

    } else if (point_in_rectangle(mouse_x, mouse_y, field_left, tuning_top, field_right, tuning_bottom)) {
        // TUNING
        active_field = 3
        keyboard_string = field_tuning
    } else {
		
		//instance_destroy()
		//obj_main_menu.pantalla=0
        active_field = -1
        keyboard_string = ""
    }
}



// NAMe
if (active_field == 0) {
    field_name = keyboard_string
}

// BASE NOTE
if (active_field == 2) {
    var s = keyboard_string
    var filtered = ""
    var len = string_length(s)
    for (var i = 1; i <= len; i++) {
        var ch = string_char_at(s, i)
        if (ch >= "0" && ch <= "9") {
            filtered += ch
        }
    }
    field_base_note = filtered;
    keyboard_string = filtered;
}

// TUNING
if (active_field == 3) {
    var s2 = keyboard_string
    var filtered2 = ""
    var len2 = string_length(s2)
    for (var j = 1; j <= len2; j++) {
        var ch2 = string_char_at(s2, j)
        if (ch2 >= "0" && ch2 <= "9") {
            filtered2 += ch2
        }
    }
    field_tuning = filtered2
    keyboard_string = filtered2
}


hover_ok = point_in_rectangle(mouse_x, mouse_y, ok_left, btn_y, ok_right, btn_y + btn_h)
hover_cancel = point_in_rectangle(mouse_x, mouse_y, cancel_left, btn_y, cancel_right, btn_y + btn_h)

var scale_lerp = 0.3
var target_ok_scale = hover_ok ? 1.1 : 1.0
var target_cancel_scale = hover_cancel ? 1.1 : 1.0

btn_scale_ok = lerp(btn_scale_ok, target_ok_scale, scale_lerp)
btn_scale_cancel = lerp(btn_scale_cancel, target_cancel_scale, scale_lerp)

if (mouse_check_button_pressed(mb_left)) {
    if (hover_ok) {
		if field_file = ""
		{
			
			exit
		}
		// HACER INSTRUMENTO
		obj_control_variables.add_instrument(field_name, field_file, field_base_note, field_tuning)

		obj_main_menu.numinstruments++
		obj_main_menu.pantalla=0
		obj_main_menu.alarm[0]=1 // CREAR INSTRUMENTOS
        instance_destroy()
    }
    if (hover_cancel) {
        instance_destroy()
		obj_main_menu.pantalla=0
    }
}