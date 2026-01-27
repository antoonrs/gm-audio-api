var mx = device_mouse_x(0)
var my = device_mouse_y(0)


if (is_undefined(ctrl) || ctrl == noone) ctrl = instance_find(obj_control_variables, 0)
if (ctrl == noone) {
    return
}

var area_x0 = piano_w
var area_y0 = top_h
var area_x1 = room_width
var area_y1 = room_height

var total_semitones = (top_midi - bottom_midi) + 1
if (total_semitones <= 0) total_semitones = 1
var key_h = (area_y1 - area_y0) / total_semitones
var note_h = key_h * 0.9

draw_set_font(font)
draw_set_color(ui_bg_color)
draw_rectangle(0,0,room_width,room_height,false)

draw_set_color(ui_topbar_color)
draw_rectangle(0,0,room_width,top_h,false)

//draw_set_color(topbar_text_color)
//draw_set_halign(fa_left)
//draw_set_valign(fa_top)
//draw_text(back_btn_x + back_btn_w + 10, 16, "Note Editor")

/*
if (is_struct(ctrl)) {
    var nbars = string(real(ctrl.bars))
    draw_set_halign(fa_right)
	draw_set_valign(fa_middle)
    draw_text(room_width - 12, top_h/2, "Compases: " + nbars)
}*/

draw_set_color(back_btn_color)
draw_roundrect_ext(back_btn_x, back_btn_y, back_btn_x + back_btn_w, back_btn_y + back_btn_h, 10,10, false)

if (back_btn_hover_alpha > 0.001) {
    draw_set_alpha(back_btn_hover_alpha)
    draw_set_color(back_btn_hover_color)
    draw_roundrect_ext(back_btn_x, back_btn_y, back_btn_x + back_btn_w, back_btn_y + back_btn_h, 10,10, false)
    draw_set_alpha(1)
}

draw_set_font(font_big)
draw_set_color(back_btn_text_color)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_text(back_btn_x + back_btn_w/2, back_btn_y + back_btn_h/2, "<")

draw_set_color(main_area_color)
draw_rectangle(area_x0, area_y0, area_x1, area_y1, false)

var total_beats = max(1, real(ctrl.bars) * real(ctrl.beatsPerBar))
var viewport_beats = (area_x1 - area_x0) / real(px_per_beat)
var start_beat = (variable_struct_exists(ctrl, "scroll_beats") ? real(ctrl.scroll_beats) : 0)
var end_beat = start_beat + viewport_beats
var start_grid = floor(start_beat) - 1
for (var b = start_grid; b <= ceil(end_beat) + 2; ++b) {
    var gx = area_x0 + (b - start_beat) * px_per_beat
    draw_set_color(grid_color)
    draw_line(gx, area_y0, gx, area_y1)
}

////////////////// NOTAS ////////////////////////////
if (!(is_undefined(ctrl) || ctrl == noone) && instr_index >= 0 && instr_index < array_length(ctrl.instruments)) {
    var instr_name = string(ctrl.instruments[instr_index].name)
    var bm = bottom_midi
    var tm = top_midi

    for (var i = 0; i < array_length(ctrl.events); ++i) {
        var ev = ctrl.events[i]
        if (string(ev.instr) != instr_name) continue

        var midi = note_string_to_midi(ev.note)
        var beat_start = real(ev.beat)
        var beat_end = real(ev.beat + ev.dur)

        //Optimizacion de no dibujar si se sale
        if (beat_end < start_beat - 1 || beat_start > end_beat + 1) continue

        var x0 = area_x0 + (beat_start - start_beat) * px_per_beat
        var x1 = area_x0 + (beat_end - start_beat) * px_per_beat

        var step_index = (top_midi - midi)
        if (step_index < 0) step_index = 0
        if (step_index >= total_semitones) step_index = total_semitones - 1
        var y_center = area_y0 + step_index * key_h + key_h * 0.5

        var y0 = y_center - note_h*0.5
        var y1 = y_center + note_h*0.5

        var col = note_color_from_midi(midi)
        draw_set_color(col)
        draw_roundrect_ext(x0,y0,x1,y1,10,10,false)

        if (i == selected_ev) {
            draw_set_color(note_outline_color)
            draw_roundrect_ext(x0-2,y0-2,x1+2,y1+2,12,12,false)
        }
    }
}

/////////////////////// PIANO ////////////////////////
draw_set_color(piano_panel_color)
draw_rectangle(0,top_h,piano_w,room_height,false)

var bm = bottom_midi
var tm = top_midi
for (var i = 0; i < total_semitones; ++i) {
    var midi = tm - i
    var y0 = area_y0 + i * key_h
    var y1 = y0 + key_h
    var pc = midi mod 12
    if (pc == 1 || pc == 3 || pc == 6 || pc == 8 || pc == 10)
        draw_set_color(piano_black_color)
    else
        draw_set_color(piano_white_color)
    draw_rectangle(0, y0, piano_w, y1, false)

	draw_set_font(font)
    // etiqueta nota
    draw_set_color(piano_label_color)
    draw_set_halign(fa_left); draw_set_valign(fa_middle)
    draw_text(6, y0 + key_h/2, midi_to_note_string(midi))
}


draw_set_font(font_big)
// Info selección
if (selected_ev >= 0 && selected_ev < array_length(ctrl.events)) {
    var evs = ctrl.events[selected_ev]
    draw_set_color(text_color_primary)
    draw_set_halign(fa_left); draw_set_valign(fa_top)
    draw_text(area_x0 + 8, area_y0 + 8, "Sel: " + evs.note + "  beat: " + string(evs.beat) + "  dur: " + string(evs.dur))
}



///////////////// SCROLL BAR /////////////////////
var track_x0 = area_x0
var track_x1 = area_x1
var track_w = track_x1 - track_x0
var track_y = area_y1 - scrollbar_margin - scrollbar_height
var thumb_w = 0
if (total_beats > 0) thumb_w = track_w * min(1, viewport_beats / total_beats)
if (thumb_w < scrollbar_min_thumb) thumb_w = min(scrollbar_min_thumb, track_w)
if (thumb_w > track_w) thumb_w = track_w

var denom_scroll = max(0.0001, total_beats - viewport_beats)
var thumb_x = track_x0
if (track_w - thumb_w > 0) {
    var scroll_beats = variable_struct_exists(ctrl, "scroll_beats") ? real(ctrl.scroll_beats) : 0
    thumb_x = track_x0 + (scroll_beats / denom_scroll) * (track_w - thumb_w)
}

// track
draw_set_color(scroll_track_color)
draw_rectangle(track_x0, track_y, track_x1, track_y + scrollbar_height, false)

var hovering_thumb = (mx >= thumb_x && mx <= thumb_x + thumb_w && my >= track_y && my <= track_y + scrollbar_height)

// overlay roja de hover
if (scroll_hover_alpha > 0.001) {
    draw_set_alpha(scroll_hover_alpha * 0.18)
    draw_set_color(back_btn_hover_color)
    draw_rectangle(track_x0, track_y, track_x1, track_y + scrollbar_height, false)
    draw_set_alpha(1)
}

draw_set_color(hovering_thumb ? scroll_thumb_hover_color : scroll_thumb_color)
draw_roundrect_ext(thumb_x, track_y, thumb_x + thumb_w, track_y + scrollbar_height, 5, 5, false)




// BOTONES
draw_set_font(font_big)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)

draw_set_color(ui_bg_color)
draw_roundrect_ext(
    btn_play_x, btn_play_y,
    btn_play_x + btn_play_w,
    btn_play_y + btn_play_h,
    8, 8, false
)

draw_set_color(text_color_primary)

var cx = btn_play_x + btn_play_w * 0.5
var cy = btn_play_y + btn_play_h * 0.5
var s  = btn_play_w * 0.22

if (!preview_playing) {
    // PLAY
    draw_triangle(cx - s, cy - s,cx - s, cy + s,cx + s, cy,false)
} else {
    // PAUSE
    var w = s * 0.45
    var h = s * 1.2

    draw_rectangle(cx - w * 2, cy - h, cx - w, cy + h, false)
    draw_rectangle(cx + w,     cy - h, cx + w * 2, cy + h, false)
}


// RESET
draw_set_color(ui_bg_color)
draw_roundrect_ext(
    btn_reset_x, btn_reset_y,
    btn_reset_x + btn_reset_w,
    btn_reset_y + btn_reset_h,
    8, 8, false
)

draw_set_color(text_color_primary)

var cx = btn_reset_x + btn_reset_w * 0.5
var cy = btn_reset_y + btn_reset_h * 0.5
var s  = btn_reset_w * 0.22

draw_rectangle(
    cx - s * 1.6, cy - s * 1,
    cx - s * 1.2, cy + s * 1,
    false
)

draw_triangle(cx + s, cy - s, cx + s, cy + s,cx - s * 0.6, cy,false)





if (preview_playing) {

    var beat = external_call(global.ext.getBeat)
    var start_beat = real(ctrl.scroll_beats)

    var xb = area_x0 + (beat - start_beat) * px_per_beat

    draw_set_color(c_white)
    draw_set_alpha(0.9)
    draw_line(xb, area_y0, xb, area_y1)
    draw_set_alpha(1)
}


var hover_play =
    mx >= btn_play_x && mx <= btn_play_x + btn_play_w &&
    my >= btn_play_y && my <= btn_play_y + btn_play_h

var hover_reset =
    mx >= btn_reset_x && mx <= btn_reset_x + btn_reset_w &&
    my >= btn_reset_y && my <= btn_reset_y + btn_reset_h

if (hover_play) {
    draw_set_alpha(0.25)
    draw_set_color(c_white)
    draw_roundrect_ext(
        btn_play_x, btn_play_y,
        btn_play_x + btn_play_w,
        btn_play_y + btn_play_h,
        8, 8, false
    )
    draw_set_alpha(1)
}

if (hover_reset) {
    draw_set_alpha(0.25)
    draw_set_color(c_white)
    draw_roundrect_ext(
        btn_reset_x, btn_reset_y,
        btn_reset_x + btn_reset_w,
        btn_reset_y + btn_reset_h,
        8, 8, false
    )
    draw_set_alpha(1)
}
