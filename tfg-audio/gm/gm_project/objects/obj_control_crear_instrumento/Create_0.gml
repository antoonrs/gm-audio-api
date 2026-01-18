textcolor = obj_main_menu.archivocolor;
offsetinstrument = obj_main_menu.offsetinstrument;
instrumentcolorbackground = obj_main_menu.instrumentcolorbackground;
instrumentcolor = obj_main_menu.instrumentcolor;
instrumentheight = obj_main_menu.instrumentheight;
instrumentwidth = obj_main_menu.instrumentwidth;
redondez = obj_main_menu.redondez;
activocolor = obj_main_menu.activocolor;


target_w = room_width / 2;
target_h = room_height / 2;

panel_w = 32;
panel_h = 32;

x = room_width  * 0.5 - target_w * 0.5;
y = room_height * 0.5 - target_h * 0.5;

panel_bounce = 0.25;
panel_opened = false;


instrument_dropdown_open = false;

selected_instrument = irandom(array_length(global.instrument_library) - 1);

instrument_dropdown_max = 10;


field_base_note = "60";

field_tuning = "440";

field_name = "Instr.";


active_field = -1;
keyboard_string = "";


field_height = 32;
field_margin_top = 72;
field_margin_side = 32;
field_sep = 32;


btn_w = 96;
btn_h = 32;

btn_scale_ok = 1;
btn_scale_cancel = 1;

hover_ok = false;
hover_cancel = false;


alphamarcadorarchivo = 0;