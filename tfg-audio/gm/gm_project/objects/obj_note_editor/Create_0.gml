top_h = 56;
piano_w = 200
back_btn_x = 8
back_btn_y = 8
back_btn_w = 36
back_btn_h = 36

// Colores parametrizables
ui_bg_color = obj_main_menu.instrumentcolorbackground
ui_topbar_color = obj_main_menu.backgroundcolor
back_btn_color = obj_main_menu.colorpianoblanco
back_btn_text_color = obj_main_menu.instrumentcolorbackgroundoscuro
back_btn_hover_color = obj_main_menu.activocolor
topbar_text_color = obj_main_menu.upperbarcolor
piano_white_color = obj_main_menu.colorpianoblanco
piano_black_color = obj_main_menu.colorpianonegro
piano_panel_color = obj_main_menu.instrumentcolorbackground
main_area_color = obj_main_menu.instrumentcolorbackgroundoscuro
grid_color = obj_main_menu.instrumentcolorbackground
note_outline_color = obj_main_menu.archivocolor
text_color_primary = obj_main_menu.backgroundcolor
piano_label_color = obj_main_menu.backgroundcolor
color_scroll = obj_main_menu.instrumentcolor

back_btn_hover_alpha = 0
back_btn_hover_speed = 0.12
back_btn_hover_max = 1.0

scrollbar_height = 12
scrollbar_margin = 8
scrollbar_min_thumb = 20
scroll_track_color = obj_main_menu.textcolor
scroll_thumb_color = obj_main_menu.archivocolor
scroll_thumb_hover_color = obj_main_menu.timelinecolor

scroll_hover_alpha = 0
scroll_hover_speed = 0.12
scroll_hover_max = 1.0

scrollbar_dragging = false
scrollbar_drag_offset = 0
scrollbar_active = false

ctrl = noone
marker = noone
instr_index = -1
px_per_beat = 120
note_default_dur = 0.8
bottom_midi = 36
top_midi = 96
selected_ev = -1
dragging = false

if (instance_exists(obj_main_menu)) obj_main_menu.pantalla = 3
_editor_init = true;

function _ctrl_has(_fn_name) {
    return (ctrl != noone) && variable_instance_exists(ctrl, _fn_name)
}


last_preview_midi = -1
last_preview_time = 0
preview_cooldown = 0.05


preview_playing = false
preview_start_beat = 0
preview_cursor_beat = 0
preview_last_beat = 0

btn_size = 36
btn_margin = 10

btn_play_x = back_btn_x + back_btn_w + 20
btn_play_y = 8
btn_play_w = btn_size
btn_play_h = btn_size

btn_reset_x = btn_play_x + btn_size + btn_margin
btn_reset_y = btn_play_y
btn_reset_w = btn_size
btn_reset_h = btn_size


function preview_toggle_play() {
    if (!preview_playing) {
        preview_playing = true
        preview_last_beat = external_call(global.ext.getBeat)
        external_call(global.ext.tplay)
    } else {
        preview_playing = false
        external_call(global.ext.tpause)
    }
}

function preview_go_to_start() {
    preview_playing = false
    preview_last_beat = 0
    external_call(global.ext.tstop)
}
