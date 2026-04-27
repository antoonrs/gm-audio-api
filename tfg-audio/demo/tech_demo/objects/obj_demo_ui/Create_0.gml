external_call(global.ext.init)

external_call(global.ext.tstop)

bus_perc = external_call(global.ext.bus_create)
bus_acom = external_call(global.ext.bus_create)
bus_melo = external_call(global.ext.bus_create)

mute_perc = false
mute_acom = false
mute_melo = false

btn_w = 260
btn_h = 60

base_y = 300

btn_perc_x = 80
btn_perc_y = base_y

btn_acom_x = 80
btn_acom_y = base_y + 110

btn_melo_x = 80
btn_melo_y = base_y + 220

btn_bpm_up_x = 420
btn_bpm_up_y = base_y

btn_bpm_down_x = 420
btn_bpm_down_y = base_y + 110

btn_quant_x = 420
btn_quant_y = base_y + 220

slider_w = 260
slider_h = 12
slider_hit_h = 30

sl_master_x = 80
sl_master_y = 200

sl_perc_x = 80
sl_perc_y = base_y + 70

sl_acom_x = 80
sl_acom_y = base_y + 180

sl_melo_x = 80
sl_melo_y = base_y + 290

vol_master = 1
vol_perc = 1
vol_acom = 1
vol_melo = 1

drag_master = false
drag_perc = false
drag_acom = false
drag_melo = false

current_bpm = 120

last_beat_int = -1
metro_flash = 0

loading = true
load_timer = 0

external_call(global.ext.songLoad, "full.json")