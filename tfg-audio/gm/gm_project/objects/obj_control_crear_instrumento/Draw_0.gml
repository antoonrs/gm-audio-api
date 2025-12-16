draw_set_font(font_big)
draw_set_halign(fa_left)
draw_set_valign(fa_top)

draw_set_color(make_color_rgb(0, 0, 0))
draw_set_alpha(0.4)
draw_rectangle(0, 0, room_width, room_height, false)
draw_set_alpha(1)

var left   = x
var top    = y
var right  = x + panel_w
var bottom = y + panel_h

draw_set_color(instrumentcolorbackground)
draw_roundrect_ext(left, top, right, bottom, redondez, redondez, false)

draw_set_color(instrumentcolorbackground)
draw_roundrect_ext(left, top, right, bottom, redondez, redondez, false)

// Título
draw_set_color(textcolor)
draw_text(left + 24, top + 24, "Create Instrument")
draw_set_font(font)

// Campos
var cur_y = top + field_margin_top
var field_left  = left  + field_margin_side
var field_right = right - field_margin_side

var r2 = redondez * 0.2

var name_top = cur_y
var name_bottom = cur_y + field_height

// Fondo campo
if (active_field == 0) {
    draw_set_color(activocolor)
} else {
    draw_set_color(make_color_rgb(220, 220, 230))
}
draw_roundrect_ext(field_left, name_top, field_right, name_bottom, r2, r2, false)

// Etiqueta
draw_set_color(textcolor)
draw_text(field_left, name_top - 20, "Name")

// Texto
draw_set_color(instrumentcolorbackground)
var text_x = field_left + 8
var text_y = name_top + 8
draw_text(text_x, text_y, field_name)

// Cursor
if (active_field == 0) {
    if ((current_time div 500) mod 2 == 0) {
        var cx = text_x + string_width(field_name)
        var cy_top = name_top + 6
        var cy_bottom = name_bottom - 6
        draw_rectangle(cx, cy_top, cx + 2, cy_bottom, false)
    }
}


// FICHERO
cur_y = name_bottom + field_sep
var file_top    = cur_y
var file_bottom = cur_y + field_height

// Fondo campo
if (active_field == 1) {
    draw_set_color(activocolor)
} else {
    draw_set_color(make_color_rgb(220, 220, 230))
}
draw_roundrect_ext(field_left, file_top, field_right, file_bottom, r2, r2, false)

// Etiqueta
draw_set_color(textcolor)
draw_text(field_left, file_top - 20, "File (.mp3 / .wav)")

// Texto
draw_set_color(instrumentcolorbackground)
var file_text = (field_file == "") ? "<click to choose file>" : field_file
text_x = field_left + 8
text_y = file_top + 8
draw_text(text_x, text_y, file_text)

cur_y = file_bottom + field_sep
var base_top    = cur_y
var base_bottom = cur_y + field_height

// Fondo campo
if (active_field == 2) {
    draw_set_color(activocolor)
} else {
    draw_set_color(make_color_rgb(220, 220, 230))
}
draw_roundrect_ext(field_left, base_top, field_right, base_bottom, r2, r2, false)

// Etiqueta
draw_set_color(textcolor)
draw_text(field_left, base_top - 20, "Base Note")

// Texto
draw_set_color(instrumentcolorbackground)
text_x = field_left + 8
text_y = base_top + 8
draw_text(text_x, text_y, field_base_note)

// Cursor
if (active_field == 2) {
    if ((current_time div 500) mod 2 == 0) {
        var cx2 = text_x + string_width(field_base_note)
        var cy2_top = base_top + 6
        var cy2_bottom = base_bottom - 6
        draw_rectangle(cx2, cy2_top, cx2 + 2, cy2_bottom, false)
    }
}

cur_y = base_bottom + field_sep
var tuning_top    = cur_y
var tuning_bottom = cur_y + field_height

if (active_field == 3) {
    draw_set_color(activocolor)
} else {
    draw_set_color(make_color_rgb(220, 220, 230))
}
draw_roundrect_ext(field_left, tuning_top, field_right, tuning_bottom, r2, r2, false)

// Etiqueta
draw_set_color(textcolor)
draw_text(field_left, tuning_top - 20, "Tuning")

// Texto
text_x = field_left + 8
text_y = tuning_top + 8
draw_set_color(instrumentcolorbackground)
draw_text(text_x, text_y, field_tuning)

// Cursor
if (active_field == 3) {
    if ((current_time div 500) mod 2 == 0) {
        var cx3 = text_x + string_width(field_tuning)
        var cy3_top = tuning_top + 6
        var cy3_bottom = tuning_bottom - 6
        draw_rectangle(cx3, cy3_top, cx3 + 2, cy3_bottom, false)
    }
}

var btn_y = bottom - field_margin_side - btn_h

// Cancel
var cancel_left  = field_left
var cancel_right = cancel_left + btn_w
var cancel_cx = (cancel_left + cancel_right) * 0.5
var cancel_cy = btn_y + btn_h * 0.5

var cw = btn_w * btn_scale_cancel * 0.5
var ch = btn_h * btn_scale_cancel * 0.5

draw_set_color(instrumentcolor);
draw_roundrect_ext(cancel_cx - cw, cancel_cy - ch, cancel_cx + cw, cancel_cy + ch, r2, r2, false)

draw_set_color(instrumentcolorbackground)
draw_text(cancel_cx - string_width("Cancel") * 0.5, cancel_cy - 8, "Cancel")

// OK
var ok_right = field_right
var ok_left  = ok_right - btn_w
var ok_cx = (ok_left + ok_right) * 0.5
var ok_cy = btn_y + btn_h * 0.5

var ow = btn_w * btn_scale_ok * 0.5
var oh = btn_h * btn_scale_ok * 0.5

draw_set_color(instrumentcolor)
draw_roundrect_ext(ok_cx - ow, ok_cy - oh, ok_cx + ow, ok_cy + oh, r2, r2, false)

draw_set_color(instrumentcolorbackground)
draw_text(ok_cx - string_width("OK") * 0.5, ok_cy - 8, "OK")