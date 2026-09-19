extends Node

# HamsterAudio generates and plays retro arcade SFX for Hamster Game.

var player_pop: AudioStreamPlayer
var player_whack: AudioStreamPlayer
var player_dizzy: AudioStreamPlayer
var player_bonus: AudioStreamPlayer
var player_penalty: AudioStreamPlayer
var player_tick: AudioStreamPlayer
var player_game_over: AudioStreamPlayer

func _ready():
	player_pop = _create_player(_generate_pop_wav())
	player_whack = _create_player(_generate_whack_wav())
	player_dizzy = _create_player(_generate_dizzy_wav())
	player_bonus = _create_player(_generate_bonus_wav())
	player_penalty = _create_player(_generate_penalty_wav())
	player_tick = _create_player(_generate_tick_wav())
	player_game_over = _create_player(_generate_game_over_wav())

func _create_player(stream: AudioStream) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p

func _exit_tree():
	for p in [player_pop, player_whack, player_dizzy, player_bonus, player_penalty, player_tick, player_game_over]:
		if is_instance_valid(p):
			p.stop()
			p.stream = null

func play_pop():
	if SettingsManager.sound_enabled and player_pop:
		player_pop.play()

func play_whack():
	if SettingsManager.sound_enabled and player_whack:
		player_whack.play()

func play_dizzy():
	if SettingsManager.sound_enabled and player_dizzy:
		player_dizzy.play()

func play_bonus():
	if SettingsManager.sound_enabled and player_bonus:
		player_bonus.play()

func play_penalty():
	if SettingsManager.sound_enabled and player_penalty:
		player_penalty.play()

func play_tick():
	if SettingsManager.sound_enabled and player_tick:
		player_tick.play()

func play_game_over():
	if SettingsManager.sound_enabled and player_game_over:
		player_game_over.play()

# --- Procedural Audio Synthesizer ---

func _generate_wav(duration: float, generator: Callable) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t = float(i) / float(rate)
		var s: float = clamp(generator.call(t, duration), -1.0, 1.0)
		var byte_val = int((s * 0.5 + 0.5) * 255.0)
		data[i] = clamp(byte_val, 0, 255)

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func _generate_pop_wav() -> AudioStreamWAV:
	return _generate_wav(0.08, func(t: float, d: float) -> float:
		var env = 1.0 - (t / d)
		var freq = lerp(500.0, 1050.0, t / d)
		return sin(t * freq * TAU) * env * 0.7
	)

func _generate_whack_wav() -> AudioStreamWAV:
	return _generate_wav(0.14, func(t: float, d: float) -> float:
		var env = exp(-t * 22.0)
		var freq = lerp(320.0, 80.0, t / d)
		var wave = sin(t * freq * TAU)
		var noise = randf_range(-0.4, 0.4) if t < 0.04 else 0.0
		return (wave * 0.7 + noise) * env
	)

func _generate_dizzy_wav() -> AudioStreamWAV:
	return _generate_wav(0.24, func(t: float, d: float) -> float:
		var env = 1.0 - (t / d)
		var vibrato = sin(t * 35.0) * 15.0
		var tone1 = sin(t * (880.0 + vibrato) * TAU) * 0.4
		var tone2 = sin(t * (1320.0 + vibrato) * TAU) * 0.3
		return (tone1 + tone2) * env
	)

func _generate_bonus_wav() -> AudioStreamWAV:
	return _generate_wav(0.28, func(t: float, d: float) -> float:
		var step = int(t / 0.07)
		var freqs = [523.25, 659.25, 783.99, 1046.50]
		var freq = freqs[clamp(step, 0, 3)]
		var sub_t = fmod(t, 0.07)
		var env = 1.0 - (sub_t / 0.07)
		return sin(t * freq * TAU) * env * 0.7
	)

func _generate_penalty_wav() -> AudioStreamWAV:
	return _generate_wav(0.22, func(t: float, d: float) -> float:
		var env = 1.0 - (t / d)
		var wave = 1.0 if fmod(t * 110.0, 1.0) < 0.5 else -1.0
		return wave * env * 0.6
	)

func _generate_tick_wav() -> AudioStreamWAV:
	return _generate_wav(0.04, func(t: float, d: float) -> float:
		var env = exp(-t * 80.0)
		return (sin(t * 1400.0 * TAU) + randf_range(-0.3, 0.3)) * env * 0.5
	)

func _generate_game_over_wav() -> AudioStreamWAV:
	return _generate_wav(0.45, func(t: float, d: float) -> float:
		var env = 1.0 - (t / d)
		var freq = lerp(750.0, 180.0, t / d)
		return sin(t * freq * TAU) * env * 0.8
	)
