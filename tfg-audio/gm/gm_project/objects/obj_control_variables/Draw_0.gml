if obj_main_menu.pantalla!=0
exit

var track_x0 = scrollbar_side_margin;
var track_x1 = room_width - scrollbar_side_margin
var track_w = track_x1 - track_x0
var track_y = room_height - scrollbar_bottom_margin - scrollbar_height

var total_beats = max(1, real(bars) * real(beatsPerBar))
var viewport_beats = (track_w) / real(px_per_beat)
var thumb_w = 0
if (total_beats > 0) thumb_w = track_w * min(1, viewport_beats / total_beats)
if (thumb_w < scrollbar_min_thumb) thumb_w = min(scrollbar_min_thumb, track_w)
if (thumb_w > track_w) thumb_w = track_w
var denom_scroll = max(0.0001, total_beats - viewport_beats)
var thumb_x = track_x0
if (track_w - thumb_w > 0) {
    thumb_x = track_x0 + (scroll_beats / denom_scroll) * (track_w - thumb_w)
}

draw_set_color(scroll_track_color)
draw_rectangle(track_x0, track_y, track_x1, track_y + scrollbar_height, false)

if (scroll_hover_alpha > 0.001) {
    draw_set_alpha(scroll_hover_alpha * 0.18)
    draw_set_color(scroll_overlay_color)
    draw_rectangle(track_x0, track_y, track_x1, track_y + scrollbar_height, false)
    draw_set_alpha(1)
}

var mx = device_mouse_x(0)
var my = device_mouse_y(0)
var hovering_thumb = (mx >= thumb_x && mx <= thumb_x + thumb_w && my >= track_y && my <= track_y + scrollbar_height)
draw_set_color(hovering_thumb ? scroll_thumb_hover_color : scroll_thumb_color)
draw_roundrect_ext(thumb_x, track_y, thumb_x + thumb_w, track_y + scrollbar_height, 6,6, false)

draw_set_color(make_color_rgb(120,120,120))
draw_roundrect_ext(thumb_x+1, track_y+1, thumb_x + thumb_w-1, track_y + scrollbar_height-1, 5,5,false)

draw_set_halign(fa_right)
draw_set_valign(fa_middle)
draw_set_color(make_color_rgb(220,220,220))
draw_text(track_x1, track_y - 10, "Compases: " + string(bars) + "  Beats totales: " + string(total_beats))