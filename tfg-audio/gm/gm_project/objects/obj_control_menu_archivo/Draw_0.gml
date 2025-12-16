draw_set_color(color)
draw_rectangle(x, y, x + width, y + lengthentrada * numentradas, false)

var textos = ["New Song","Open Song","Import MIDI","Export MIDI","Save","Save As"]

if (alphamarcadorarchivo > 0 && hover_index != -1) {
    draw_set_alpha(alphamarcadorarchivo)
    draw_set_color(activocolor)
    
    var top_hover    = y + hover_index * lengthentrada
    var bottom_hover = top_hover + lengthentrada
    draw_rectangle(x, top_hover, x + width, bottom_hover, false)
    
    draw_set_alpha(1)
}

draw_set_color(textcolor)
for (var i = 0; i < numentradas; i++) {
    var top    = y + i * lengthentrada
    var middle = top + lengthentrada * 0.5
    draw_set_halign(fa_center)
    draw_set_valign(fa_middle)
    draw_text(x + width/2, middle, textos[i])
}