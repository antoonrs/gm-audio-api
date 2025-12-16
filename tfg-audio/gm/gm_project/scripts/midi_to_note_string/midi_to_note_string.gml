function midi_to_note_string(m) {
    var pc = m mod 12
    var octave = floor(m / 12) - 1
    var name = ""
    switch (pc) {
        case 0: name = "C"; break
        case 1: name = "C#"; break
        case 2: name = "D"; break
        case 3: name = "D#"; break
        case 4: name = "E"; break
        case 5: name = "F"; break
        case 6: name = "F#"; break
        case 7: name = "G"; break
        case 8: name = "G#"; break
        case 9: name = "A"; break
        case 10: name = "A#"; break
        case 11: name = "B"; break
    }
    return name + string(octave);
}