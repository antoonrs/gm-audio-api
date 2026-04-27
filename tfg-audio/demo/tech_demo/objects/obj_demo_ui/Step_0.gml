var beat = external_call(global.ext.getBeat)

load_timer += 1

if (loading)
{
    if (load_timer > 10)
    {
        external_call(global.ext.songPlay)
        loading = false
    }
}

var beat_int = floor(beat)
var beat_visual = (beat_int mod 4) + 1

if (beat_int != last_beat_int)
{
    last_beat_int = beat_int
    metro_flash = 6
}

if (metro_flash > 0)
    metro_flash--

var mx = mouse_x
var my = mouse_y

if (mouse_check_button_pressed(mb_left))
{
    if (point_in_rectangle(mx,my,btn_perc_x,btn_perc_y,btn_perc_x+btn_w,btn_perc_y+btn_h))
    {
        mute_perc = !mute_perc
        external_call(global.ext.bus_set_mute, bus_perc, mute_perc)
    }

    if (point_in_rectangle(mx,my,btn_acom_x,btn_acom_y,btn_acom_x+btn_w,btn_acom_y+btn_h))
    {
        mute_acom = !mute_acom
        external_call(global.ext.bus_set_mute, bus_acom, mute_acom)
    }

    if (point_in_rectangle(mx,my,btn_melo_x,btn_melo_y,btn_melo_x+btn_w,btn_melo_y+btn_h))
    {
        mute_melo = !mute_melo
        external_call(global.ext.bus_set_mute, bus_melo, mute_melo)
    }

    if (point_in_rectangle(mx,my,btn_bpm_up_x,btn_bpm_up_y,btn_bpm_up_x+btn_w,btn_bpm_up_y+btn_h))
    {
        current_bpm += 5
        external_call(global.ext.setTempo, current_bpm)
    }

    if (point_in_rectangle(mx,my,btn_bpm_down_x,btn_bpm_down_y,btn_bpm_down_x+btn_w,btn_bpm_down_y+btn_h))
    {
        current_bpm -= 5
        if (current_bpm < 30) current_bpm = 30
        external_call(global.ext.setTempo, current_bpm)
    }

    if (point_in_rectangle(mx,my,btn_quant_x,btn_quant_y,btn_quant_x+btn_w,btn_quant_y+btn_h))
    {
        external_call(global.ext.playQ, "efecto.mp3", 1.0)
    }

    if (point_in_rectangle(mx,my,sl_master_x,sl_master_y-slider_hit_h/2,sl_master_x+slider_w,sl_master_y+slider_hit_h/2)) drag_master = true
    if (point_in_rectangle(mx,my,sl_perc_x,sl_perc_y-slider_hit_h/2,sl_perc_x+slider_w,sl_perc_y+slider_hit_h/2)) drag_perc = true
    if (point_in_rectangle(mx,my,sl_acom_x,sl_acom_y-slider_hit_h/2,sl_acom_x+slider_w,sl_acom_y+slider_hit_h/2)) drag_acom = true
    if (point_in_rectangle(mx,my,sl_melo_x,sl_melo_y-slider_hit_h/2,sl_melo_x+slider_w,sl_melo_y+slider_hit_h/2)) drag_melo = true
}

if (mouse_check_button(mb_left))
{
    if (drag_master) vol_master = clamp((mx - sl_master_x) / slider_w, 0, 1)
    if (drag_perc) vol_perc = clamp((mx - sl_perc_x) / slider_w, 0, 1)
    if (drag_acom) vol_acom = clamp((mx - sl_acom_x) / slider_w, 0, 1)
    if (drag_melo) vol_melo = clamp((mx - sl_melo_x) / slider_w, 0, 1)
}

if (mouse_check_button_released(mb_left))
{
    drag_master = false
    drag_perc = false
    drag_acom = false
    drag_melo = false
}

external_call(global.ext.bus_set_vol, bus_perc, vol_perc * vol_master)
external_call(global.ext.bus_set_vol, bus_acom, vol_acom * vol_master)
external_call(global.ext.bus_set_vol, bus_melo, vol_melo * vol_master)