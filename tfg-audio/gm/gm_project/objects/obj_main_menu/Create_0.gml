depth=-1

// CONSTANTES ELEMENTOS

colorpianoblanco = make_color_rgb(175,215,235)
colorpianonegro = make_color_rgb(30,30,60)

textcolor = make_color_rgb(30,30,30)

backgroundcolor = make_color_rgb(235,240,245)

instrumentcolorbackgroundoscuro = make_color_rgb(10,15,30)

upperbarheight = 48
upperbarcolor = make_color_rgb(175,215,235)

archivolength = 228
archivocolor = make_color_rgb(220,220,240)
archivotexto = "File"
alphamarcadorarchivo = 0
activocolor = make_color_rgb(250,150,150)

timelineheight = 128
timelinecolor = make_color_rgb(200,205,210)

instrumentcolor = make_color_rgb(255,220,120)
instrumentcolorbackground = make_color_rgb(40,45,50)
instrumentheight = 164
instrumentwidth = 256
yinstrument = upperbarheight+timelineheight
sep = 16 // Separacion entre casillas de instrumentos

offsetinstrument = 0 // Esto es lo que va deslizando
moveinstrument = 25 // Maximo de aceleracion de deslizar instrumentos

offsetbotonmas = 30 // Lo que se resta al tamaño de la caja de instrumentos para el boton +
grosorbotonmas = 6 // Grosor del mas
redondez = 100


numinstruments = 0
pantalla = 0
/*
Pantalla 
0 - menu principal
1 - mini menu archivo
2 - menu de crear instrumento
3 - menu de editar notas
4 - menu de instrumento
5 - menu de buses
*/

alarm[0]=1