external_call(global.ext.songStop);
external_call(global.ext.songLoad, "overworld.json");
external_call(global.ext.songPlay);

bus_1 = external_call(global.ext.bus_create)
bus_2 = external_call(global.ext.bus_create)
bus_3 = external_call(global.ext.bus_create)
bus_4 = external_call(global.ext.bus_create)
bus_5 = external_call(global.ext.bus_create)

fase = 0;

bus_vol = array_create(6, 0)

fade_speed = 0.02;

bus_vol[1] = 1;

for (var i = 1; i <= 5; i++) {
    external_call(global.ext.bus_set_vol, i, bus_vol[i]);
}