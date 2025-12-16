y = yinstrument + indice * (instrumentheight + sep) + offsetinstrument

//draw_set_color(instrumentcolorbackground)
//draw_rectangle(0, y, room_width, y + instrumentheight, false)

draw_set_color(instrumentcolor)
draw_roundrect_ext(-300, y-sep/2, instrumentwidth, y + instrumentheight+sep/2,redondez,redondez, false)

draw_set_font(font_big)
draw_set_color(textcolor)
draw_set_halign(fa_center)
draw_set_valign(fa_middle)
draw_text(instrumentwidth/2,y+instrumentheight/4,field_name)