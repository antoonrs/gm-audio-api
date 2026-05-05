if (keyboard_check_pressed(ord("S")) && keyboard_check(vk_control)) {
    savelocation = export_song_to_json(savelocation)
}


var track_x0 = scrollbar_side_margin
var track_x1 = room_width - scrollbar_side_margin
var track_w = track_x1 - track_x0
var track_y = room_height - scrollbar_bottom_margin - scrollbar_height

var total_beats = max(1, real(bars) * real(beatsPerBar))
var viewport_beats = (track_w) / real(px_per_beat)

if (is_undefined(scroll_beats)) scroll_beats = 0
if (scroll_beats < 0) scroll_beats = 0
if (scroll_beats > max(0, total_beats - viewport_beats)) scroll_beats = max(0, total_beats - viewport_beats)

var thumb_w = 0
if (total_beats > 0) thumb_w = track_w * min(1, viewport_beats / total_beats)
if (thumb_w < scrollbar_min_thumb) thumb_w = min(scrollbar_min_thumb, track_w)
if (thumb_w > track_w) thumb_w = track_w

var denom_scroll = max(0.0001, total_beats - viewport_beats)
var thumb_x = track_x0
if (track_w - thumb_w > 0) {
    thumb_x = track_x0 + (scroll_beats / denom_scroll) * (track_w - thumb_w)
}

var mx = device_mouse_x(0)
var my = device_mouse_y(0)
var mlp = mouse_check_button_pressed(mb_left)
var ml  = mouse_check_button(mb_left)

var scroll_enabled = false
if (instance_exists(obj_main_menu)) {
    scroll_enabled = (obj_main_menu.pantalla == 0)
} else {
    scroll_enabled = false
}

var hovering_scroll_now = (mx >= track_x0 && mx <= track_x1 && my >= track_y && my <= track_y + scrollbar_height)
var target_alpha = hovering_scroll_now ? scroll_hover_max : 0
scroll_hover_alpha += (target_alpha - scroll_hover_alpha) * scroll_hover_speed

if (scroll_enabled) {
    if (mlp) {
        if (mx >= track_x0 && mx <= track_x1 && my >= track_y && my <= track_y + scrollbar_height) {
            _scrollbar_active = true
            if (mx >= thumb_x && mx <= thumb_x + thumb_w) {
                _scrollbar_dragging = true
                _scrollbar_drag_offset = mx - thumb_x
            } else {
                var click_rel = mx - track_x0
                var new_thumb_x = click_rel - thumb_w * 0.5
                if (new_thumb_x < 0) new_thumb_x = 0
                if (new_thumb_x > track_w - thumb_w) new_thumb_x = track_w - thumb_w
                var ratio = (track_w - thumb_w) > 0 ? (new_thumb_x / (track_w - thumb_w)) : 0
                scroll_beats = ratio * denom_scroll
                if (scroll_beats < 0) scroll_beats = 0
                if (scroll_beats > denom_scroll) scroll_beats = denom_scroll
            }
        }
    }

    if (_scrollbar_dragging) {
        if (ml) {
            var new_thumb_abs = mx - _scrollbar_drag_offset
            var new_thumb_rel = new_thumb_abs - track_x0
            if (new_thumb_rel < 0) new_thumb_rel = 0
            if (new_thumb_rel > track_w - thumb_w) new_thumb_rel = track_w - thumb_w
            var ratio2 = (track_w - thumb_w) > 0 ? (new_thumb_rel / (track_w - thumb_w)) : 0
            scroll_beats = ratio2 * denom_scroll
            if (scroll_beats < 0) scroll_beats = 0
            if (scroll_beats > denom_scroll) scroll_beats = denom_scroll
        } else {
            _scrollbar_dragging = false
            _scrollbar_active = false
        }
    }

    if (!ml && _scrollbar_active && !_scrollbar_dragging) {
        _scrollbar_active = false
    }

    if (keyboard_check_pressed(vk_left)) {
        scroll_beats -= 1
        if (scroll_beats < 0) scroll_beats = 0
    }
    if (keyboard_check_pressed(vk_right)) {
        scroll_beats += 1
        if (scroll_beats > denom_scroll) scroll_beats = denom_scroll
    }
    if (keyboard_check_pressed(vk_pageup)) {
        scroll_beats -= max(1, floor(viewport_beats))
        if (scroll_beats < 0) scroll_beats = 0
    }
    if (keyboard_check_pressed(vk_pagedown)) {
        scroll_beats += max(1, floor(viewport_beats))
        if (scroll_beats > denom_scroll) scroll_beats = denom_scroll
    }
}

if (scroll_beats < 0) scroll_beats = 0
if (scroll_beats > denom_scroll) scroll_beats = denom_scroll




///// AUTO MOVIMIENTO
var mm = instance_find(obj_main_menu, 0)

if (mm != noone && mm.song_playing) {

    var beat = external_call(global.ext.getBeat)

    var total_beats = max(1, real(bars) * real(beatsPerBar))

    var viewport_beats = (room_width - scrollbar_side_margin*2) / real(px_per_beat)

    var margin = viewport_beats * 0.3 // margen de 30%

    var target = beat - margin

    if (target < 0) target = 0

    var max_scroll = max(0, total_beats - viewport_beats)
    if (target > max_scroll) target = max_scroll

    scroll_beats = lerp(scroll_beats, target, 0.2)
	
	
}