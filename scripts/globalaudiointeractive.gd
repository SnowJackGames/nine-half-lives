extends AudioStreamPlayer


var rng = RandomNumberGenerator.new()

func _play_music(music: AudioStream, volume = 0.0):
	if stream == music:
		return
		
	stream = music 
	volume_db = volume
	play()
	
func _play_music_random_start( music: AudioStream, volume = 0.0):
	if stream == music:
		return
		
	stream = music 
	volume_db = volume
	play(rng.randf_range(0.0, 540.0))
	
func play_music_level(track, volume = 0.0):
		_play_music(track)

func play_music_level_random_start(track, volume = 0.0):
		_play_music_random_start(track,volume)
		
func play_FX(given_stream: AudioStream, volume = 0.0):
	var fx_player = AudioStreamPlayer.new()
	fx_player.stream = given_stream
	fx_player.name = "FX_PLAYER"
	fx_player.volume_db = volume
	add_child(fx_player)
	fx_player.play()
	
	await fx_player.finished
	
	fx_player.queue_free()
	
