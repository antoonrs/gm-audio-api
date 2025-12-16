var mx = device_mouse_x(0)
var my = device_mouse_y(0)
var mlp = mouse_check_button_pressed(mb_left)

if (mlp) and obj_main_menu.pantalla=0{
    var yy  = marker.y
    var ih  = marker.instrumentheight
    var x_start = marker.instrumentwidth
    var x_end   = room_width
    if (mx >= x_start && mx <= x_end && my >= yy && my <= yy + ih) {
        var existing = instance_find(obj_note_editor, 0)
        if (existing != noone) {
            with (existing) instance_destroy()
        }

        var ed = instance_create_depth(0, 0, -2, obj_note_editor)
        ed.marker = marker
        ed.instr_index = marker.indice
        if (instance_exists(obj_main_menu)) obj_main_menu.pantalla = 3
    }
}