var beat = external_call(global.ext.getBeat)

var beat_int = floor(beat)
var beat_frac = beat - beat_int

var beat_visual = (beat_int mod 4) + 1
var bar = floor(beat_int / 4) + 1

var beat_in_bar = (beat_int mod 4) + beat_frac
var progress = beat_in_bar / 4

draw_set_color(make_color_rgb(10,10,18))
draw_rectangle(0,0,display_get_width(),display_get_height(),false)

draw_set_color(c_white)
draw_text(40,40,"Beat global: " + string_format(beat,1,2))
draw_text(40,70,"Compas: " + string(bar))
draw_text(40,100,"Tiempo: " + string(beat_visual))
draw_text(40,130,"BPM: " + string(current_bpm))


if (metro_flash > 0)
    draw_set_color(make_color_rgb(255,90,90))
else
    draw_set_color(make_color_rgb(70,70,70))

draw_circle(720,100,35,false)


draw_set_color(make_color_rgb(40,40,60))
draw_rectangle(600,160,840,175,false)

draw_set_color(make_color_rgb(255,140,60))
draw_rectangle(600,160,600+240*progress,175,false)


var col_on = make_color_rgb(70,200,140)
var col_off = make_color_rgb(80,80,90)

if (mute_perc) draw_set_color(col_off) else draw_set_color(col_on)
draw_roundrect(btn_perc_x,btn_perc_y,btn_perc_x+btn_w,btn_perc_y+btn_h,false)
draw_set_color(c_white)
draw_text(btn_perc_x+20,btn_perc_y+20,"Percusion")

if (mute_acom) draw_set_color(col_off) else draw_set_color(col_on)
draw_roundrect(btn_acom_x,btn_acom_y,btn_acom_x+btn_w,btn_acom_y+btn_h,false)
draw_set_color(c_white)
draw_text(btn_acom_x+20,btn_acom_y+20,"Acomp")

if (mute_melo) draw_set_color(col_off) else draw_set_color(col_on)
draw_roundrect(btn_melo_x,btn_melo_y,btn_melo_x+btn_w,btn_melo_y+btn_h,false)
draw_set_color(c_white)
draw_text(btn_melo_x+20,btn_melo_y+20,"Melodia")


draw_set_color(make_color_rgb(70,120,255))
draw_roundrect(btn_bpm_up_x,btn_bpm_up_y,btn_bpm_up_x+btn_w,btn_bpm_up_y+btn_h,false)
draw_set_color(c_white)
draw_text(btn_bpm_up_x+20,btn_bpm_up_y+20,"BPM +")

draw_set_color(make_color_rgb(70,120,255))
draw_roundrect(btn_bpm_down_x,btn_bpm_down_y,btn_bpm_down_x+btn_w,btn_bpm_down_y+btn_h,false)
draw_set_color(c_white)
draw_text(btn_bpm_down_x+20,btn_bpm_down_y+20,"BPM -")

draw_set_color(make_color_rgb(255,200,80))
draw_roundrect(btn_quant_x,btn_quant_y,btn_quant_x+btn_w,btn_quant_y+btn_h,false)
draw_set_color(c_black)
draw_text(btn_quant_x+20,btn_quant_y+20,"Play cuantizado")


draw_set_color(make_color_rgb(50,50,70))
draw_rectangle(sl_master_x,sl_master_y,sl_master_x+slider_w,sl_master_y+slider_h,false)
draw_set_color(make_color_rgb(120,180,255))
draw_rectangle(sl_master_x,sl_master_y,sl_master_x+slider_w*vol_master,sl_master_y+slider_h,false)
draw_set_color(c_white)
draw_circle(sl_master_x+slider_w*vol_master,sl_master_y+slider_h/2,12,false)


draw_set_color(make_color_rgb(50,50,70))
draw_rectangle(sl_perc_x,sl_perc_y,sl_perc_x+slider_w,sl_perc_y+slider_h,false)
draw_set_color(make_color_rgb(120,180,255))
draw_rectangle(sl_perc_x,sl_perc_y,sl_perc_x+slider_w*vol_perc,sl_perc_y+slider_h,false)
draw_set_color(c_white)
draw_circle(sl_perc_x+slider_w*vol_perc,sl_perc_y+slider_h/2,12,false)


draw_set_color(make_color_rgb(50,50,70))
draw_rectangle(sl_acom_x,sl_acom_y,sl_acom_x+slider_w,sl_acom_y+slider_h,false)
draw_set_color(make_color_rgb(120,180,255))
draw_rectangle(sl_acom_x,sl_acom_y,sl_acom_x+slider_w*vol_acom,sl_acom_y+slider_h,false)
draw_set_color(c_white)
draw_circle(sl_acom_x+slider_w*vol_acom,sl_acom_y+slider_h/2,12,false)


draw_set_color(make_color_rgb(50,50,70))
draw_rectangle(sl_melo_x,sl_melo_y,sl_melo_x+slider_w,sl_melo_y+slider_h,false)
draw_set_color(make_color_rgb(120,180,255))
draw_rectangle(sl_melo_x,sl_melo_y,sl_melo_x+slider_w*vol_melo,sl_melo_y+slider_h,false)
draw_set_color(c_white)
draw_circle(sl_melo_x+slider_w*vol_melo,sl_melo_y+slider_h/2,12,false)