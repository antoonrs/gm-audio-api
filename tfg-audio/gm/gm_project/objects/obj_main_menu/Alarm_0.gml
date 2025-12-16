// INSTRUMENTOS

for (var i = 0; i < numinstruments; i++)
{
	var yinst = yinstrument + i * (instrumentheight + sep) + offsetinstrument
    var marcador = instance_create_depth(1,yinst,-1,obj_marcador_instrumento)
	marcador.yinstrument=yinstrument
	marcador.indice=i
}