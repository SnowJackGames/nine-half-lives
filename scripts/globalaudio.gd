extends AudioStreamPlayer

## Specify the default volume (normalized from 0.0 to 1.0)
@export_range(0, 1, 0.1) var default_volume: float = 1.0

## The duration of the fade in seconds
@export_range(0, 5, 0.1) var duration: float = 10.0

var _tween: Tween

func playVolume(vol) -> void:
	default_volume = vol
	
func fadeInTime(seconds) -> void:
	duration = seconds
	
## Toggles the volume to fade in/out
func toggle(randomstart = 0.0) -> void:
	if _tween and _tween.is_running():
		_tween.stop()
	_tween = get_tree().create_tween()
	
	if !playing:
		_set_volume(0.0)
		play(randomstart)
		_tween.tween_method(_set_volume, db_to_linear(volume_db), default_volume, duration)
	else:
		_tween.tween_method(_set_volume, db_to_linear(volume_db), 0.0, duration)
		_tween.chain().tween_callback(stop)

func _set_volume(vol: float) -> void:
	volume_db = linear_to_db(vol)

var rng = RandomNumberGenerator.new()

func _play_music(music: AudioStream, volume = 0.0):
	if stream == music:
		return
		
	stream = music 
	volume_db = volume
	toggle()
	
func _play_music_random_start( music: AudioStream, volume = 0.0):
	if stream == music:
		return
		
	stream = music 
	volume_db = volume
	toggle(rng.randf_range(0.0, 540.0))
	
	
func play_music_level(track, volume = 0.0):
		_play_music(track,volume)
		
func _play_music_from(time, music: AudioStream, volume = 0.0):
	if stream == music:
		return
		
	stream = music 
	volume_db = volume
	play(time)

func play_music_from_time(track, time, volume = 0.0):
		_play_music_from(time, track, volume)

func play_music_level_random_start(track, volume = 0.0):
		_play_music_random_start(track,volume)
		
func play_FX(given_stream: AudioStream, volume = 0.0, offset = 0.0):
	var fx_player = AudioStreamPlayer.new()
	fx_player.stream = given_stream
	fx_player.name = "FX_PLAYER"
	fx_player.volume_db = volume
	add_child(fx_player)
	fx_player.play(offset)
	
	await fx_player.finished
	
	fx_player.queue_free()
	
	
