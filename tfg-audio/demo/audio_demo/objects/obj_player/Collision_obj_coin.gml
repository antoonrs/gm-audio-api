// Increase the coins variable of the player by 1
coins += 1;

// Create an instance of obj_coin_collect_effect at the position of the 'other' instance, which is the
// coin that the player touched.
instance_create_layer(other.x, other.y, "Instances", obj_coin_collect_effect);

// Play the coin collect sound
external_call(global.ext.play, "snd_coin_collect.wav")

// Destroy the 'other' instance, which is the coin.
instance_destroy(other);


if coins>5
{obj_audio_in_game.fase=1}
if coins>10
{obj_audio_in_game.fase=2}
if coins>15
{obj_audio_in_game.fase=3}
if coins>20
{obj_audio_in_game.fase=4}
if coins>25
{obj_audio_in_game.fase=5}