depth=1

yinstrument=0
indice=0

sep=obj_main_menu.sep
offsetinstrument=obj_main_menu.offsetinstrument
textcolor=obj_main_menu.textcolor
instrumentcolorbackground=obj_main_menu.instrumentcolorbackground
instrumentcolor=obj_main_menu.instrumentcolor
instrumentheight=obj_main_menu.instrumentheight
instrumentwidth=obj_main_menu.instrumentwidth
redondez=obj_main_menu.redondez

field_name = ""
field_file = ""
field_base_note = 0
field_tuning = 0

function actualizar_datos() {
    var lista = obj_control_variables.instruments
    var len = array_length(lista);

    if (len == 0) {
        show_debug_message("No hay instrumentos cargados.")
        return;
    }

    indice = clamp(indice, 0, len - 1)

    var ins = lista[indice]

    field_name = ins.name
    field_file = ins.file
    field_base_note = ins.baseNote
    field_tuning = ins.tuningHz
}


var roll = instance_create_depth(0, 0, 2, obj_roll_instrumento)

roll.indice = indice
roll.yinstrument = yinstrument
roll.sep = sep
roll.instrumentheight = instrumentheight
roll.instrumentwidth = instrumentwidth
roll.marker = id