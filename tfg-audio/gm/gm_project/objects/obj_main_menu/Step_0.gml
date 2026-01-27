
// MENU PRINCIPAL

if pantalla = 0{

	// MOVER INSTRUMENTOS

	if numinstruments>2{ // Solo se puede mover si hay mas de 2 instrumentos
		if mouse_wheel_down() {
			if offsetinstrument>-numinstruments*instrumentheight
			{
				offsetinstrument-=moveinstrument
			}
		}

		if mouse_wheel_up(){
			if offsetinstrument<0
			{
				offsetinstrument+=moveinstrument
			}
		}
	}
	offsetinstrument=clamp(offsetinstrument,-numinstruments*instrumentheight,0)


	//////// BOTON MAS
	var offset_base = 30
	var grosor_base = 6

	var offset_hover = offset_base * 0.5
	var grosor_hover = grosor_base * 2

	var yb = yinstrument + numinstruments * (instrumentheight + sep) + offsetinstrument

	var left   = offsetbotonmas
	var top    = yb + offsetbotonmas
	var right  = instrumentwidth - offsetbotonmas
	var bottom = yb + instrumentheight - offsetbotonmas

	var hover = point_in_rectangle(mouse_x, mouse_y, left, top, right, bottom)

	var bounce = 0.25

	if (hover) {
	    offsetbotonmas = lerp(offsetbotonmas, offset_hover, bounce)
	    grosorbotonmas = lerp(grosorbotonmas, grosor_hover, bounce)
	} else {
	    offsetbotonmas = lerp(offsetbotonmas, offset_base, bounce)
	    grosorbotonmas = lerp(grosorbotonmas, grosor_base, bounce)
	}

	if (mouse_check_button_pressed(mb_left)) and hover {
		pantalla=2
		instance_create_depth(room_width/2,room_height/2,-3,obj_control_crear_instrumento)
	}

	////////// BARRA ARCHIVO
	hover = point_in_rectangle(mouse_x, mouse_y, 0,0,archivolength,upperbarheight)
	bounce = 0.25
	if (hover) {
	    alphamarcadorarchivo = lerp(alphamarcadorarchivo, 1, bounce)
	} else {
	    alphamarcadorarchivo = lerp(alphamarcadorarchivo, 0, bounce)
	}

	if (mouse_check_button_pressed(mb_left)) and hover {
		pantalla=1
		instance_create_depth(0,upperbarheight,-2,obj_control_menu_archivo)
	}





	// SPACE = PLAY / PAUSE
	if (keyboard_check_pressed(vk_space)) {

	    if (!song_playing) {

	        // Arrancar transport
	        external_call(global.ext.tplay);

	        // Sincronizar TODOS los instrumentos al beat actual
	        var b = external_call(global.ext.getBeat);
	        with (obj_roll_instrumento) {
	            last_emit_beat = b;
	        }

	        song_playing = true;

	    } else {
	        external_call(global.ext.tpause);
	        song_playing = false;
	    }
	}

	// ENTER = RESET
	if (keyboard_check_pressed(vk_enter)) {

	    // Parar transport
	    external_call(global.ext.tstop);

	    // Resetear estado temporal de TODOS los instrumentos
	    with (obj_roll_instrumento) {
	        last_emit_beat = 0;
	    }

	    song_playing = false;
	}

	// BOTONES
	if (mouse_check_button_pressed(mb_left)) {

	    // PLAY
	    if (point_in_rectangle(mouse_x, mouse_y,
	        btn_play_x, btn_play_y,
	        btn_play_x + btn_play_w,
	        btn_play_y + btn_play_h))
	    {
	        if (!song_playing) {

	            external_call(global.ext.tplay);

	            var b = external_call(global.ext.getBeat);
	            with (obj_roll_instrumento) {
	                last_emit_beat = b;
	            }

	            song_playing = true;

	        } else {
	            external_call(global.ext.tpause);
	            song_playing = false;
	        }
	    }

	    // RESET
	    if (point_in_rectangle(mouse_x, mouse_y,
	        btn_reset_x, btn_reset_y,
	        btn_reset_x + btn_reset_w,
	        btn_reset_y + btn_reset_h))
	    {
	        external_call(global.ext.tstop);

	        with (obj_roll_instrumento) {
	            last_emit_beat = 0;
	        }

	        song_playing = false;
	    }
	}













} // pantalla = 0

if pantalla = 1
{
	
}





