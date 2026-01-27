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
		
		// Parar reproduccion
		var mm = instance_find(obj_main_menu, 0);
		if (mm != noone && mm.song_playing) {
		    external_call(global.ext.tstop)
		    with (obj_roll_instrumento) {
		        last_emit_beat = 0;
		    }
		    mm.song_playing = false;
		}

    }
}









var ctrl = instance_find(obj_control_variables, 0);
if (ctrl == noone) exit;

var mm = instance_find(obj_main_menu, 0);
if (mm == noone || !mm.song_playing) exit;

var idx = marker.indice;
if (idx < 0 || idx >= array_length(ctrl.instruments)) exit;

var instr_name = string(ctrl.instruments[idx].name);

var beat_now = external_call(global.ext.getBeat);
if (beat_now <= last_emit_beat) exit;

for (var i = 0; i < array_length(ctrl.events); i++) {

    var ev = ctrl.events[i];
    if (string(ev.instr) != instr_name) continue;

    if (ev.beat >= last_emit_beat && ev.beat < beat_now) {

        var inst = ctrl.instruments[idx];
        var base_note = global.instrument_library[idx].base_note;
        var desc = inst.file + "|NOTE:" + ev.note + "|BASE:" + string(base_note);

        external_call(global.ext.preview_note, desc, ev.vel, ev.dur);
    }
}

last_emit_beat = beat_now;
