draw_set_font(font_big);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

draw_set_color(make_color_rgb(0, 0, 0));
draw_set_alpha(0.4);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(1);

var left   = x;
var top    = y;
var right  = x + panel_w;
var bottom = y + panel_h;

draw_set_color(instrumentcolorbackground);
draw_roundrect_ext(left, top, right, bottom, redondez, redondez, false);

draw_set_color(textcolor);
draw_text(left + 24, top + 24, "Create Instrument");
draw_set_font(font);


var cur_y = top + field_margin_top;
var field_left  = left  + field_margin_side;
var field_right = right - field_margin_side;

var r2 = redondez * 0.2;


var name_top = cur_y;
var name_bottom = cur_y + field_height;

draw_set_color(active_field == 0 ? activocolor : make_color_rgb(220,220,230));
draw_roundrect_ext(field_left, name_top, field_right, name_bottom, r2, r2, false);

draw_set_color(textcolor);
draw_text(field_left, name_top - 20, "Name");

draw_set_color(instrumentcolorbackground);
var text_x = field_left + 8;
var text_y = name_top + 8;
draw_text(text_x, text_y, field_name);

// Cursor
if (active_field == 0 && (current_time div 500) mod 2 == 0) {
    var cx = text_x + string_width(field_name);
    draw_rectangle(cx, name_top + 6, cx + 2, name_bottom - 6, false);
}

cur_y = name_bottom + field_sep;


draw_set_color(textcolor);
draw_text(field_left, cur_y - 20, "Instrument");

var box_top = cur_y;
var box_bottom = box_top + field_height;

// Campo principal
draw_set_color(make_color_rgb(220,220,230));
draw_roundrect_ext(field_left, box_top, field_right, box_bottom, r2, r2, false);

// Texto seleccionado
var inst = global.instrument_library[selected_instrument];
draw_set_color(instrumentcolorbackground);
draw_text(field_left + 8, box_top + 8, inst.name);

// Flecha
draw_text(field_right - 20, box_top + 8, instrument_dropdown_open ? "▲" : "▼");

cur_y = box_bottom + field_sep;


var base_top = cur_y;
var base_bottom = cur_y + field_height;

draw_set_color(make_color_rgb(200,200,200));
draw_roundrect_ext(field_left, base_top, field_right, base_bottom, r2, r2, false);

draw_set_color(textcolor);
draw_text(field_left, base_top - 20, "Base Note (fixed)");

draw_set_color(instrumentcolorbackground);
draw_text(field_left + 8, base_top + 8, field_base_note);

cur_y = base_bottom + field_sep;


var tuning_top = cur_y;
var tuning_bottom = cur_y + field_height;

draw_set_color(active_field == 3 ? activocolor : make_color_rgb(220,220,230));
draw_roundrect_ext(field_left, tuning_top, field_right, tuning_bottom, r2, r2, false);

draw_set_color(textcolor);
draw_text(field_left, tuning_top - 20, "Tuning (fixed)");

draw_set_color(instrumentcolorbackground);
draw_text(field_left + 8, tuning_top + 8, field_tuning);

// Cursor
if (active_field == 3 && (current_time div 500) mod 2 == 0) {
    var cx3 = field_left + 8 + string_width(field_tuning);
    draw_rectangle(cx3, tuning_top + 6, cx3 + 2, tuning_bottom - 6, false);
}


var btn_y = bottom - field_margin_side - btn_h;

// Cancel
var cancel_left  = field_left;
var cancel_right = cancel_left + btn_w;
var cancel_cx = (cancel_left + cancel_right) * 0.5;
var cancel_cy = btn_y + btn_h * 0.5;

var cw = btn_w * btn_scale_cancel * 0.5;
var ch = btn_h * btn_scale_cancel * 0.5;

draw_set_color(instrumentcolor);
draw_roundrect_ext(cancel_cx - cw, cancel_cy - ch, cancel_cx + cw, cancel_cy + ch, r2, r2, false);

draw_set_color(instrumentcolorbackground);
draw_text(cancel_cx - string_width("Cancel") * 0.5, cancel_cy - 8, "Cancel");

// OK
var ok_right = field_right;
var ok_left  = ok_right - btn_w;
var ok_cx = (ok_left + ok_right) * 0.5;
var ok_cy = btn_y + btn_h * 0.5;

var ow = btn_w * btn_scale_ok * 0.5;
var oh = btn_h * btn_scale_ok * 0.5;

draw_set_color(instrumentcolor);
draw_roundrect_ext(ok_cx - ow, ok_cy - oh, ok_cx + ow, ok_cy + oh, r2, r2, false);

draw_set_color(instrumentcolorbackground);
draw_text(ok_cx - string_width("OK") * 0.5, ok_cy - 8, "OK");



if (instrument_dropdown_open) {

    draw_set_alpha(0.5);
    draw_set_color(c_black);
    draw_rectangle(0, 0, room_width, room_height, false);
    draw_set_alpha(1);

    var h = field_height;
    var count = min(instrument_dropdown_max, array_length(global.instrument_library));

    for (var i = 0; i < count; i++) {
        var itop = box_bottom + i * (h + 4);
        var ibot = itop + h;

        draw_set_color(
            i == selected_instrument
            ? activocolor
            : make_color_rgb(235,235,240)
        );

        draw_roundrect_ext(field_left, itop, field_right, ibot, r2, r2, false);

        draw_set_color(instrumentcolorbackground);
        draw_text(field_left + 8, itop + 8, global.instrument_library[i].name);
    }
}
