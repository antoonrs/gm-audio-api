if (marker == noone) exit

var yy = marker.y
var ih = marker.instrumentheight
var sep = marker.sep

draw_set_color(marker.instrumentcolorbackground)
draw_rectangle(0, yy, room_width, yy + ih, false)

var ctrl = instance_find(obj_control_variables, 0)
if (ctrl == noone) exit

if (!is_array(ctrl.instruments) || !is_array(ctrl.events)) exit

var idx = marker.indice
if (idx < 0 || idx >= array_length(ctrl.instruments)) exit

var ins = ctrl.instruments[idx]
var instr_name = string(ins.name)

var scroll_beats = 0;
if (!is_undefined(ctrl.scroll_beats)) {
    scroll_beats = ctrl.scroll_beats
}

var x_start = marker.instrumentwidth
var x_end   = room_width

var view_width = x_end - x_start
if (view_width <= 0) exit

var view_beats = view_width / px_per_beat

for (var i = 0; i < array_length(ctrl.events); i++) {
    var ev = ctrl.events[i]

    if (string(ev.instr) != instr_name) continue

    var ev_start = ev.beat
    var ev_end   = ev.beat + ev.dur

    if (ev_end   < scroll_beats) continue
    if (ev_start > scroll_beats + view_beats) continue

    var x0 = x_start + (ev_start - scroll_beats) * px_per_beat
    var x1 = x_start + (ev_end   - scroll_beats) * px_per_beat

    var midi = note_string_to_midi(ev.note)

    if (midi < bottom_midi || midi > top_midi) continue

    var range = max(1, top_midi - bottom_midi)
    var t = (midi - bottom_midi) / range

    var y_center = yy + ih - t * ih

    var note_h = ih / 12
    var y0 = y_center - note_h * 0.5
    var y1 = y_center + note_h * 0.5

    draw_set_color(note_color_from_midi(midi))

    draw_roundrect_ext(x0, y0, x1, y1, 10, 10, false)

}