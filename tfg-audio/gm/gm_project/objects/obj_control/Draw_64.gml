draw_set_color(c_white);
draw_set_font(-1);

var beat = external_call(global.ext.getBeat);

draw_text(16, 16, "Beat: " + string_format(beat, 0, 2));
draw_text(16, 40, "Controles:");
draw_text(16, 60, "T = Transport Play");
draw_text(16, 80, "Y = Transport Pause");
draw_text(16,100, "I = Transport Stop");
draw_text(16,120, "G/H = Cambiar Tempo (128 / 100 BPM)");