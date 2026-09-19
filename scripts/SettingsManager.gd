extends Node

# SettingsManager singleton dispatches settings updates across RETRORA.

signal sound_toggled(enabled: bool)
signal music_toggled(enabled: bool)
signal screen_shake_toggled(enabled: bool)
signal crt_filter_toggled(enabled: bool)

var sound_enabled: bool = true
var music_enabled: bool = true
var screen_shake_enabled: bool = true
var vibration_enabled: bool = true
var crt_filter_enabled: bool = false

func _ready():
	load_settings()

func load_settings():
	sound_enabled = SaveManager.get_setting("sound", true)
	music_enabled = SaveManager.get_setting("music", true)
	screen_shake_enabled = SaveManager.get_setting("screen_shake", true)
	vibration_enabled = SaveManager.get_setting("vibration", true)
	crt_filter_enabled = SaveManager.get_setting("crt_filter", false)

	# Apply initial states
	apply_all()

func apply_all():
	AudioManager.set_mute(not sound_enabled)
	crt_filter_toggled.emit(crt_filter_enabled)

func set_sound(enabled: bool):
	sound_enabled = enabled
	SaveManager.set_setting("sound", enabled)
	AudioManager.set_mute(not sound_enabled)
	sound_toggled.emit(sound_enabled)

func set_music(enabled: bool):
	music_enabled = enabled
	SaveManager.set_setting("music", enabled)
	music_toggled.emit(music_enabled)

func set_screen_shake(enabled: bool):
	screen_shake_enabled = enabled
	SaveManager.set_setting("screen_shake", enabled)
	screen_shake_toggled.emit(screen_shake_enabled)

func set_vibration(enabled: bool):
	vibration_enabled = enabled
	SaveManager.set_setting("vibration", enabled)

func set_crt_filter(enabled: bool):
	crt_filter_enabled = enabled
	SaveManager.set_setting("crt_filter", enabled)
	crt_filter_toggled.emit(crt_filter_enabled)

func reset_defaults():
	SaveManager.reset_all_settings()
	load_settings()
