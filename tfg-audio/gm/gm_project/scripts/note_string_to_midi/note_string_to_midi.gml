function note_string_to_midi(note_str) {
    if (!is_string(note_str)) return 60
    var s = string_upper(string(note_str))
    var L = string_length(s)
    if (L < 2) return 60
    var p = L
    while (p > 0) {
        var ch = string_char_at(s, p)
        if (ch >= "0" && ch <= "9") p--; else break
    }
    var name_part  = string_copy(s, 1, p)
    var octave_str = string_copy(s, p + 1, L - p)
    var octave = real(octave_str)
    var semitone = 0
    if (name_part == "C") semitone = 0
    else if (name_part == "C#" || name_part == "DB") semitone = 1
    else if (name_part == "D") semitone = 2
    else if (name_part == "D#" || name_part == "EB") semitone = 3
    else if (name_part == "E") semitone = 4
    else if (name_part == "F") semitone = 5
    else if (name_part == "F#" || name_part == "GB") semitone = 6
    else if (name_part == "G") semitone = 7;
    else if (name_part == "G#" || name_part == "AB") semitone = 8
    else if (name_part == "A") semitone = 9;
    else if (name_part == "A#" || name_part == "BB") semitone = 10
    else if (name_part == "B") semitone = 11
    else return 60
    var midi = (octave + 1) * 12 + semitone
    return midi
}