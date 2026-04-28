for (var i = 1; i <= 5; i++) {

    var target = (i <= fase + 1) ? 1 : 0;
	
    if (bus_vol[i] < target) {
        bus_vol[i] = min(bus_vol[i] + fade_speed, target);
    }
    else if (bus_vol[i] > target) {
        bus_vol[i] = max(bus_vol[i] - fade_speed, target);
    }

    external_call(global.ext.bus_set_vol, i, bus_vol[i]);
}


if (keyboard_check_pressed(ord("Z"))) fase = 0;
if (keyboard_check_pressed(ord("X"))) fase = 1;
if (keyboard_check_pressed(ord("C"))) fase = 2;
if (keyboard_check_pressed(ord("V"))) fase = 3;
if (keyboard_check_pressed(ord("B"))) fase = 4;