extends Node

# AudioManager singleton provides simple music and SFX playback.

var music_player: AudioStreamPlayer = null
var sfx_player: AudioStreamPlayer = null

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	# Placeholder silent audio stream to keep Godot happy
	var silence = AudioStreamGenerator.new()
	silence.mix_rate = 44100
	music_player.stream = silence
	sfx_player.stream = silence
	set_music_volume(0.8)
	set_sfx_volume(0.8)

func play_music(stream: AudioStream) -> void:
	if music_player:
		music_player.stream = stream
		music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func play_sfx(stream: AudioStream) -> void:
	if sfx_player:
		sfx_player.stream = stream
		sfx_player.play()

func set_music_volume(value: float) -> void:
	if music_player:
		music_player.volume_db = linear_to_db(clamp(value, 0.0, 1.0))

func set_sfx_volume(value: float) -> void:
	if sfx_player:
		sfx_player.volume_db = linear_to_db(clamp(value, 0.0, 1.0))

func set_mute(mute: bool) -> void:
	if music_player:
		music_player.stream_paused = mute
	if sfx_player:
		sfx_player.stream_paused = mute

func play_jump():
	pass

func play_collect():
	pass

func play_hurt():
	pass

func play_level_complete():
	pass
