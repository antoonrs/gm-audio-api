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