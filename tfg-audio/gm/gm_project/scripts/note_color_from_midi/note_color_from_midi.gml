function note_color_from_midi(midi) {
    var pc = midi mod 12

    switch (pc) {
        case 0:  return make_color_rgb(110,185,245) // C
        case 1:  return make_color_rgb(170,140,235) // C#
        case 2:  return make_color_rgb(90,215,200)  // D
        case 3:  return make_color_rgb(200,200,255) // D#
        case 4:  return make_color_rgb(140,230,170) // E
        case 5:  return make_color_rgb(80,160,220)  // F
        case 6:  return make_color_rgb(60,120,200)  // F#
        case 7:  return make_color_rgb(120,150,255) // G
        case 8:  return make_color_rgb(190,170,225) // G#
        case 9:  return make_color_rgb(120,210,160) // A
        case 10: return make_color_rgb(235,220,150) // A#
        case 11: return make_color_rgb(95,135,195)  // B
    }

    return make_color_rgb(200,220,235)
}