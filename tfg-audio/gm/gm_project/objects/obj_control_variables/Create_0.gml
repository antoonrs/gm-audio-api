depth=-10

bpm = 120
beatsPerBar = 4
bars = 1
loop_song = true

instruments = []
events = []

savelocation = ""

numinstruments = 0

function Instrument(_name, _file, _baseNote, _tuningHz) {
    return {name: _name,file: _file,baseNote: real(_baseNote),tuningHz: real(_tuningHz)}
}

function EventNote(_instrName, _note, _beat, _dur, _vel, _bus) {
    return {instr: _instrName,note: _note,beat: _beat,dur: _dur,vel: _vel,bus: _bus}
}

function add_instrument(name, file, baseNote, tuningHz) {
    if (typeof(instruments) != "array") instruments = []

    var ins = {name: string(name),file: string(file),baseNote: real(baseNote),tuningHz: real(tuningHz)}

    array_push(instruments, ins)

    numinstruments = array_length(instruments)
    //show_debug_message("INSTRUMENTO AÑADIDO, NOMBRE: '" + ins.name + "' ; NUM=" + string(numinstruments))

    return numinstruments - 1
}

function add_event(instrName, note, beat, dur, vel, bus) {
    if (is_undefined(dur)) dur = 0.0
    if (is_undefined(vel)) vel = 1.0
    if (is_undefined(bus)) bus = 0
    var ev = EventNote(instrName, note, beat, dur, vel, bus)
    array_push(events, ev)
    //show_debug_message("obj_control_variables.add_event -> added event for instr='" + string(instrName) + "' beat=" + string(beat))
    return array_length(events) - 1
}

function delete_event(idx) {
    if (typeof(events) != "array") return false
    idx = real(idx)
    if (idx < 0 || idx >= array_length(events)) return false

    array_delete(events, idx, 1);

    //show_debug_message("obj_control_variables.delete_event -> deleted event idx=" + string(idx))
    return true;
}


//add_event("triangle","C4",1.0,1.0,1.0,1)

// import_song_from_json()


history = []
history_pos = -1
history_limit = 50

function _deep_copy_events(src_events) {
    var out = []
    var n = (typeof(src_events) == "array") ? array_length(src_events) : 0
    for (var i = 0; i < n; ++i) {
        var e = src_events[i]
        var c = {
            instr: string(e.instr),
            note: string(e.note),
            beat: real(e.beat),
            dur: real(e.dur),
            vel: real(e.vel),
            bus: real(e.bus)
        }
        array_push(out, c)
    }
    return out
}

function _deep_copy_instruments(src_ins) {
    var out = []
    var n = (typeof(src_ins) == "array") ? array_length(src_ins) : 0
    for (var i = 0; i < n; ++i) {
        var ins = src_ins[i]
        var c = {
            name: string(ins.name),
            file: string(ins.file),
            baseNote: real(ins.baseNote),
            tuningHz: real(ins.tuningHz)
        };
        array_push(out, c)
    }
    return out
}

function save_state() {
    var snap = {
        events: _deep_copy_events(events),
        instruments: _deep_copy_instruments(instruments)
    }

    var histlen = array_length(history)
    if (history_pos < histlen - 1) {
        var remove_count = histlen - 1 - history_pos
        array_delete(history, history_pos + 1, remove_count)
    }

    array_push(history, snap)
    history_pos = array_length(history) - 1

    if (array_length(history) > history_limit) {
        var excess = array_length(history) - history_limit
        array_delete(history, 0, excess)
        history_pos -= excess
        if (history_pos < 0) history_pos = -1
    }
}

function undo_state() {
    if (history_pos <= 0) {
        //show_debug_message("UNDO -> no hay más estados para deshacer.")
        return
    }

    // retroceder y tomar snapshot
    history_pos -= 1
    var snap = history[history_pos]
    if (!is_struct(snap)) {
        show_debug_message("UNDO -> snapshot inválido.")
        return
    }

    // Restaurar instrumentos
    instruments = []
    var ins_snap = snap.instruments
    for (var i = 0; i < array_length(ins_snap); ++i) {
        var s = ins_snap[i]
        array_push(instruments, { name: s.name, file: s.file, baseNote: real(s.baseNote), tuningHz: real(s.tuningHz) })
    }

    // Restaurar events
    events = []
    var ev_snap = snap.events
    for (var j = 0; j < array_length(ev_snap); ++j) {
        var ss = ev_snap[j]
        array_push(events, { instr: ss.instr, note: ss.note, beat: real(ss.beat), dur: real(ss.dur), vel: real(ss.vel), bus: real(ss.bus) })
    }

    // sincronizar contador y UI
    numinstruments = array_length(instruments)
    var mm = instance_find(obj_main_menu, 0)
    if (mm != noone) {
        mm.alarm[0] = 1
        mm.numinstruments = numinstruments
    }

    //show_debug_message("UNDO restaurado estado. history_pos=" + string(history_pos))
}


/////////////// PARA EL SCROLL

scroll_beats = 0
px_per_beat = 120

scrollbar_bottom_margin = 8
scrollbar_height = 12
scrollbar_side_margin = 16
scrollbar_min_thumb = 20

// colores
scroll_track_color = make_color_rgb(80,80,80)
scroll_thumb_color = make_color_rgb(200,200,200)
scroll_thumb_hover_color = make_color_rgb(180,180,180)
scroll_overlay_color = make_color_rgb(220,40,40)

// hover
scroll_hover_alpha = 0
scroll_hover_speed = 0.12
scroll_hover_max = 1.0

// estado runtime
_scrollbar_dragging = false
_scrollbar_drag_offset = 0
_scrollbar_active = false