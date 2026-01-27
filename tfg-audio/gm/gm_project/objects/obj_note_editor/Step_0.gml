if (!variable_instance_exists(id, "ctrl")) ctrl = instance_find(obj_control_variables, 0)
if (ctrl == noone) {
    var mx_tmp = device_mouse_x(0)
    var my_tmp = device_mouse_y(0)
    var mlp_tmp = mouse_check_button_pressed(mb_left)
    if (mlp_tmp && mx_tmp >= back_btn_x && mx_tmp <= back_btn_x + back_btn_w && my_tmp >= back_btn_y && my_tmp <= back_btn_y + back_btn_h) {
        obj_main_menu.pantalla = 0
        instance_destroy()
    }
    exit;
}

if (!variable_struct_exists(ctrl, "scroll_beats")) ctrl.scroll_beats = 0

// Input
var mx = device_mouse_x(0)
var my = device_mouse_y(0)
var mlp = mouse_check_button_pressed(mb_left)
var ml = mouse_check_button(mb_left)
var mrp = mouse_check_button(mb_right)

var hovering_back_now = (mx >= back_btn_x && mx <= back_btn_x + back_btn_w && my >= back_btn_y && my <= back_btn_y + back_btn_h)
var target_alpha_back = hovering_back_now ? back_btn_hover_max : 0
back_btn_hover_alpha += (target_alpha_back - back_btn_hover_alpha) * back_btn_hover_speed

var area_x0 = piano_w
var area_y0 = top_h
var area_x1 = room_width;
var area_y1 = room_height;

var total_semitones = (top_midi - bottom_midi) + 1
if (total_semitones <= 0) total_semitones = 1
var key_h = (area_y1 - area_y0) / total_semitones
var note_h = key_h * 0.9

var total_beats = max(1, real(ctrl.bars) * real(ctrl.beatsPerBar))
var viewport_beats = (area_x1 - area_x0) / real(px_per_beat)

if (ctrl.scroll_beats < 0) ctrl.scroll_beats = 0
if (ctrl.scroll_beats > max(0, total_beats - viewport_beats)) ctrl.scroll_beats = max(0, total_beats - viewport_beats)

var track_x0 = area_x0
var track_x1 = area_x1
var track_w = track_x1 - track_x0
var track_y = area_y1 - scrollbar_margin - scrollbar_height
var thumb_w = 0;
if (total_beats > 0) thumb_w = track_w * min(1, viewport_beats / total_beats)
if (thumb_w < scrollbar_min_thumb) thumb_w = min(scrollbar_min_thumb, track_w)
if (thumb_w > track_w) thumb_w = track_w

var denom_scroll = max(0.0001, total_beats - viewport_beats)
var thumb_x = track_x0
if (track_w - thumb_w > 0) {
    thumb_x = track_x0 + (ctrl.scroll_beats / denom_scroll) * (track_w - thumb_w)
}

var hovering_scroll_now = (mx >= track_x0 && mx <= track_x1 && my >= track_y && my <= track_y + scrollbar_height)
var target_alpha_scroll = hovering_scroll_now ? scroll_hover_max : 0
scroll_hover_alpha += (target_alpha_scroll - scroll_hover_alpha) * scroll_hover_speed

if (mlp) {
    if (mx >= track_x0 && mx <= track_x1 && my >= track_y && my <= track_y + scrollbar_height) {
        scrollbar_active = true
        if (mx >= thumb_x && mx <= thumb_x + thumb_w) {
            scrollbar_dragging = true
            scrollbar_drag_offset = mx - thumb_x
        } else {
            var click_rel = mx - track_x0
            var new_thumb_x = click_rel - thumb_w * 0.5
            if (new_thumb_x < 0) new_thumb_x = 0
            if (new_thumb_x > track_w - thumb_w) new_thumb_x = track_w - thumb_w
            var ratio = (track_w - thumb_w) > 0 ? (new_thumb_x / (track_w - thumb_w)) : 0
            ctrl.scroll_beats = ratio * denom_scroll
            if (ctrl.scroll_beats < 0) ctrl.scroll_beats = 0
            if (ctrl.scroll_beats > denom_scroll) ctrl.scroll_beats = denom_scroll
        }
    }
}

if (scrollbar_dragging) {
    if (ml) {
        var new_thumb_abs = mx - scrollbar_drag_offset
        var new_thumb_rel = new_thumb_abs - track_x0
        if (new_thumb_rel < 0) new_thumb_rel = 0
        if (new_thumb_rel > track_w - thumb_w) new_thumb_rel = track_w - thumb_w
        var ratio2 = (track_w - thumb_w) > 0 ? (new_thumb_rel / (track_w - thumb_w)) : 0
        ctrl.scroll_beats = ratio2 * denom_scroll
        if (ctrl.scroll_beats < 0) ctrl.scroll_beats = 0
        if (ctrl.scroll_beats > denom_scroll) ctrl.scroll_beats = denom_scroll
    } else {
        scrollbar_dragging = false
        scrollbar_active = false
    }
}

if (!ml && scrollbar_active && !scrollbar_dragging) {
    scrollbar_active = false
}

/// TECLADO

var small_step = 1
var large_step = max(1, floor(viewport_beats))
if (keyboard_check_pressed(vk_left)) {
    ctrl.scroll_beats -= small_step;
    if (ctrl.scroll_beats < 0) ctrl.scroll_beats = 0
}
if (keyboard_check_pressed(vk_right)) {
    ctrl.scroll_beats += small_step
    if (ctrl.scroll_beats > denom_scroll) ctrl.scroll_beats = denom_scroll
}
if (keyboard_check_pressed(vk_pageup)) {
    ctrl.scroll_beats -= large_step
    if (ctrl.scroll_beats < 0) ctrl.scroll_beats = 0
}
if (keyboard_check_pressed(vk_pagedown)) {
    ctrl.scroll_beats += large_step
    if (ctrl.scroll_beats > denom_scroll) ctrl.scroll_beats = denom_scroll
}


if (keyboard_check(vk_control) && keyboard_check_pressed(ord("Z"))) {
    if (_ctrl_has("undo_state")) ctrl.undo_state()
    exit;
}

if (scrollbar_active) {
    if (mlp) {
        if (mx >= back_btn_x && mx <= back_btn_x + back_btn_w && my >= back_btn_y && my <= back_btn_y + back_btn_h) {
            if (instance_exists(obj_main_menu)) obj_main_menu.pantalla = 0
            instance_destroy()
            exit
        }
    }
    exit
}

//// PROCESAR NOTAS

// Validar instrumento
if (instr_index < 0 || instr_index >= array_length(ctrl.instruments)) {
    if (mlp && mx >= back_btn_x && mx <= back_btn_x + back_btn_w && my >= back_btn_y && my <= back_btn_y + back_btn_h) {
        if (instance_exists(obj_main_menu)) obj_main_menu.pantalla = 0
        instance_destroy()
    }
    exit;
}
var instr_name = string(ctrl.instruments[instr_index].name)

// Back button
if (mlp) {
    if (mx >= back_btn_x && mx <= back_btn_x + back_btn_w && my >= back_btn_y && my <= back_btn_y + back_btn_h) {
        if (instance_exists(obj_main_menu)) obj_main_menu.pantalla = 0
        instance_destroy()
        exit
    }
}

// RIGHT CLICK: borrar nota
if (mrp) {
    var to_delete = -1
    var evcount = array_length(ctrl.events)
    for (var i = 0; i < evcount; ++i) {
        var ev = ctrl.events[i]
        if (string(ev.instr) != instr_name) continue

        var ex0 = area_x0 + (real(ev.beat) - real(ctrl.scroll_beats)) * real(px_per_beat)
        var ex1 = area_x0 + (real(ev.beat + ev.dur) - real(ctrl.scroll_beats)) * real(px_per_beat)

        var em = note_string_to_midi(ev.note)

        var step_index = (top_midi - em)
        if (step_index < 0) step_index = 0
        if (step_index >= total_semitones) step_index = total_semitones - 1
        var y_center = area_y0 + step_index * key_h + key_h * 0.5

        var ey0 = y_center - note_h * 0.5
        var ey1 = y_center + note_h * 0.5

        if (mx >= ex0 && mx <= ex1 && my >= ey0 && my <= ey1) {
			to_delete = i
			break
		}
    }

    if (to_delete != -1) {
        var ok = false
        if (_ctrl_has("delete_event")) {
            ok = ctrl.delete_event(to_delete)
        } else {
            array_delete(ctrl.events, to_delete, 1)
            ok = true
        }

        if (ok) {
            if (selected_ev == to_delete) selected_ev = -1
            else if (selected_ev > to_delete) selected_ev -= 1
        }
    }
}

// LEFT CLICK: seleccionar o crear nota
if (mlp) {
    if (mx >= area_x0 && mx <= area_x1 && my >= area_y0 && my <= area_y1) {

        var found = -1
        var evcount2 = array_length(ctrl.events)
        for (var i = 0; i < evcount2; ++i) {
            var ev = ctrl.events[i]
            if (string(ev.instr) != instr_name) continue

            var ex0 = area_x0 + (real(ev.beat) - real(ctrl.scroll_beats)) * real(px_per_beat)
            var ex1 = area_x0 + (real(ev.beat + ev.dur) - real(ctrl.scroll_beats)) * real(px_per_beat)

            var em = note_string_to_midi(ev.note)

            var step_index2 = (top_midi - em)
            if (step_index2 < 0) step_index2 = 0
            if (step_index2 >= total_semitones) step_index2 = total_semitones - 1
            var y_center2 = area_y0 + step_index2 * key_h + key_h * 0.5

            var ey0 = y_center2 - note_h * 0.5
            var ey1 = y_center2 + note_h * 0.5

            if (mx >= ex0 && mx <= ex1 && my >= ey0 && my <= ey1) {
				found = i
				break 
			}
        }

        if (found != -1) {
            if (!dragging) {
                if (_ctrl_has("save_state")) ctrl.save_state()
            }
            selected_ev = found
            dragging = true
            drag_origin_mouse_x = mx
            drag_origin_beat = real(ctrl.events[found].beat)
            drag_origin_midi = note_string_to_midi(ctrl.events[found].note)
        }
        else {
            if (_ctrl_has("save_state")) ctrl.save_state()

            var nb = ((mx - area_x0) / real(px_per_beat)) + real(ctrl.scroll_beats)
            if (nb < 0) nb = 0
            var snap = 1/16
            if (snap > 0) nb = round(nb / snap) * snap

            var denom_y = (area_y1 - area_y0)
            var t = 0.5
            if (denom_y != 0) {
                t = (area_y1 - my) / denom_y
                if (t < 0) t = 0
                if (t > 1) t = 1
            }
            var nm = round(bottom_midi + t * (top_midi - bottom_midi))
            var nn = midi_to_note_string(nm)

            var new_idx = -1
            if (_ctrl_has("add_event")) {
                new_idx = ctrl.add_event(instr_name, nn, nb, note_default_dur, 1.0, 0)
            } else {
                var newev = { instr: instr_name, note: nn, beat: nb, dur: note_default_dur, vel: 1.0, bus: 0 }
                if (typeof(ctrl.events) != "array") ctrl.events = []
                array_push(ctrl.events, newev)
                new_idx = array_length(ctrl.events) - 1
            }
			
            var nm = round(bottom_midi + t * (top_midi - bottom_midi))
            var nn = midi_to_note_string(nm)
			var inst = ctrl.instruments[instr_index];
			var base_note = global.instrument_library[instr_index].base_note;
			var desc = inst.file + "|NOTE:" + nn + "|BASE:" + string(base_note);
			external_call(global.ext.preview_note, desc, 0.7, 0.12);




            selected_ev = new_idx

            dragging = true
            drag_origin_mouse_x = mx
            drag_origin_beat = nb
            drag_origin_midi = nm;
        }
    }
}

// DRAG: mover nota

if (dragging && ml && selected_ev >= 0 && selected_ev < array_length(ctrl.events)) {

    var dx = mx - drag_origin_mouse_x
    var new_beat = drag_origin_beat + dx / real(px_per_beat)
    if (new_beat < 0) new_beat = 0

    var snap2 = 1/16
    if (snap2 > 0) new_beat = round(new_beat / snap2) * snap2

    var denom_y2 = (area_y1 - area_y0)
    var t2 = (denom_y2 != 0) ? (area_y1 - my) / denom_y2 : 0.5
    t2 = clamp(t2, 0, 1)

    var new_midi = round(bottom_midi + t2 * (top_midi - bottom_midi))

    ctrl.events[selected_ev].beat = new_beat
    ctrl.events[selected_ev].note = midi_to_note_string(new_midi)

    var now = current_time / 1000
    if (new_midi != last_preview_midi && now - last_preview_time > preview_cooldown) {

        last_preview_midi = new_midi
        last_preview_time = now

        var nm = round(bottom_midi + t2 * (top_midi - bottom_midi))
		var nn = midi_to_note_string(nm)

		var inst = ctrl.instruments[instr_index]
		var base_note = global.instrument_library[instr_index].base_note
		var desc = inst.file + "|NOTE:" + nn + "|BASE:" + string(base_note)

		external_call(global.ext.preview_note, desc, 0.9, 0.25)

    }
}




if (!ml && dragging) dragging = false

if (selected_ev >= array_length(ctrl.events)) selected_ev = -1




if (keyboard_check_pressed(vk_space)) {
    preview_toggle_play()
}

if (keyboard_check_pressed(vk_enter)) {
    preview_go_to_start()
}


if (mlp) {

    // PLAY / PAUSE
    if (mx >= btn_play_x && mx <= btn_play_x + btn_play_w &&
        my >= btn_play_y && my <= btn_play_y + btn_play_h) {

        preview_toggle_play()
    }

    // RESET
    if (mx >= btn_reset_x && mx <= btn_reset_x + btn_reset_w &&
        my >= btn_reset_y && my <= btn_reset_y + btn_reset_h) {

        preview_go_to_start()
    }
}




if (preview_playing) {

    var current_beat = external_call(global.ext.getBeat)

    var instr_name = string(ctrl.instruments[instr_index].name)

    for (var i = 0; i < array_length(ctrl.events); ++i) {
        var ev = ctrl.events[i]
        if (string(ev.instr) != instr_name) continue

        var ev_beat = real(ev.beat)

        if (ev_beat >= preview_last_beat && ev_beat < current_beat) {

            var nn = ev.note
            var inst = ctrl.instruments[instr_index]
            var base_note = global.instrument_library[instr_index].base_note

            var desc = inst.file + "|NOTE:" + nn + "|BASE:" + string(base_note)

            external_call(
                global.ext.preview_note,
                desc,
                ev.vel,
                ev.dur
            )
        }
    }

    preview_last_beat = current_beat
}


