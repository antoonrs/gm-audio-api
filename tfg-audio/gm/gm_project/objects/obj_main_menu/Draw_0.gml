// FONDO
draw_set_alpha(1)

draw_set_font(font)

// BOTON MAS

var yb = yinstrument + numinstruments * (instrumentheight + sep) + offsetinstrument

// Rectángulo grande
draw_set_color(instrumentcolor)
draw_roundrect_ext(offsetbotonmas, yb+offsetbotonmas, instrumentwidth-offsetbotonmas, yb+instrumentheight-offsetbotonmas,redondez,redondez, false)

// Centro
var xc = instrumentwidth * 0.5
var yc = yb + instrumentheight * 0.5

// Tamaño del símbolo +
var L = instrumentheight * 0.4
var G = grosorbotonmas

draw_set_color(textcolor)

// Barra vertical
draw_roundrect_ext(xc-G*0.5, yc-L*0.5, xc+G*0.5, yc+L*0.5,10,10, false)

// Barra horizontal
draw_roundrect_ext(xc-L*0.5, yc-G*0.5, xc+L*0.5, yc+G*0.5,10,10, false)




// BARRA SUPERIOR
draw_set_color(upperbarcolor)
draw_rectangle(0,0,room_width,upperbarheight,false)

// ARCHIVO
draw_set_color(archivocolor)
draw_rectangle(0,0,archivolength,upperbarheight,false)

draw_set_color(activocolor)
draw_set_alpha(alphamarcadorarchivo)
draw_rectangle(0,0,archivolength,upperbarheight,false)
draw_set_alpha(1)

draw_set_color(textcolor)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_text(archivolength/2,upperbarheight/2,archivotexto)

// TIMELINE BARRA
draw_set_color(timelinecolor)
draw_rectangle(0,upperbarheight,room_width,upperbarheight+timelineheight,false)





// FONDO BOTÓN PLAY
draw_set_color(upperbarcolor);
draw_roundrect_ext(
    btn_play_x, btn_play_y,
    btn_play_x + btn_play_w, btn_play_y + btn_play_h,
    6, 6, false
);

// ICONO
draw_set_color(textcolor);

if (!song_playing) {
    draw_triangle(
        btn_play_x + 10, btn_play_y + 7,
        btn_play_x + 10, btn_play_y + btn_play_h - 7,
        btn_play_x + btn_play_w - 7, btn_play_y + btn_play_h * 0.5,
        false);
} else {
    draw_rectangle(btn_play_x + 9,  btn_play_y + 7, btn_play_x + 13, btn_play_y + btn_play_h - 7, false);
    draw_rectangle(btn_play_x + 19, btn_play_y + 7, btn_play_x + 23, btn_play_y + btn_play_h - 7, false);
}



// FONDO BOTÓN RESET
draw_set_color(upperbarcolor);
draw_roundrect_ext(
    btn_reset_x, btn_reset_y,
    btn_reset_x + btn_reset_w, btn_reset_y + btn_reset_h,
    6, 6, false);

// ICONO
draw_set_color(textcolor);

// barra
draw_rectangle(
    btn_reset_x + 9, btn_reset_y + 7,
    btn_reset_x + 13, btn_reset_y + btn_reset_h - 7,
    false);

// triangulo
draw_triangle(
    btn_reset_x + 24, btn_reset_y + 7,
    btn_reset_x + 24, btn_reset_y + btn_reset_h - 7,
    btn_reset_x + 13, btn_reset_y + btn_reset_h * 0.5,false);