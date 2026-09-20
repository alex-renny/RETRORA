extends Node

# SettingsManager singleton dispatches settings updates & theme palettes across RETRORA.

signal sound_toggled(enabled: bool)
signal music_toggled(enabled: bool)
signal screen_shake_toggled(enabled: bool)
signal crt_filter_toggled(enabled: bool)
signal theme_changed(theme_name: String)

var sound_enabled: bool = true
var music_enabled: bool = true
var screen_shake_enabled: bool = true
var vibration_enabled: bool = true
var crt_filter_enabled: bool = false
var current_theme: String = "light"

func _ready():
	load_settings()

func load_settings():
	sound_enabled = SaveManager.get_setting("sound", true)
	music_enabled = SaveManager.get_setting("music", true)
	screen_shake_enabled = SaveManager.get_setting("screen_shake", true)
	vibration_enabled = SaveManager.get_setting("vibration", true)
	crt_filter_enabled = SaveManager.get_setting("crt_filter", false)
	current_theme = SaveManager.get_setting("theme", "light")

	apply_all()

func apply_all():
	AudioManager.set_mute(not sound_enabled)
	crt_filter_toggled.emit(crt_filter_enabled)
	theme_changed.emit(current_theme)

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

func set_theme(theme_name: String):
	current_theme = theme_name
	SaveManager.set_setting("theme", theme_name)
	theme_changed.emit(current_theme)

func toggle_theme() -> String:
	var next = "dark" if current_theme == "light" else "light"
	set_theme(next)
	return next

func is_light_theme() -> bool:
	return current_theme == "light"

func get_palette() -> Dictionary:
	if current_theme == "light":
		return {
			"bg": Color(0.97, 0.98, 0.99),           # #F8FAFC porcelain light canvas
			"card_bg": Color(1.0, 1.0, 1.0),          # #FFFFFF pure white card
			"card_border": Color(0.88, 0.91, 0.94),   # #E2E8F0 soft slate border
			"text_primary": Color(0.06, 0.09, 0.16),  # #0F172A deep slate text
			"text_secondary": Color(0.39, 0.45, 0.55),# #64748B slate blue text
			"text_accent": Color(0.15, 0.39, 0.92),   # #2563EB royal blue
			"btn_bg": Color(1.0, 1.0, 1.0),           # white button base
			"btn_border": Color(0.82, 0.86, 0.9),     # clean border
			"accent_btn": Color(0.23, 0.51, 0.96),    # electric blue
			"accent_success": Color(0.06, 0.73, 0.51),# emerald
			"accent_warning": Color(0.96, 0.62, 0.04),# amber gold
			"accent_danger": Color(0.94, 0.27, 0.27), # coral red
			"modal_bg": Color(0.96, 0.97, 0.99, 0.96),# translucent light modal
			"grid_line": Color(0.88, 0.91, 0.94, 0.6)
		}
	else:
		return {
			"bg": Color(0.04, 0.05, 0.08),           # #040508 deep dark space
			"card_bg": Color(0.07, 0.09, 0.13),       # dark slate card
			"card_border": Color(0.18, 0.25, 0.35),   # slate border
			"text_primary": Color(0.97, 0.98, 0.99),  # crisp white
			"text_secondary": Color(0.6, 0.65, 0.75), # muted text
			"text_accent": Color(0.25, 0.85, 1.0),    # neon cyan
			"btn_bg": Color(0.1, 0.12, 0.18),         # dark button base
			"btn_border": Color(0.25, 0.35, 0.45),    # dark border
			"accent_btn": Color(0.25, 0.85, 1.0),     # cyan
			"accent_success": Color(0.25, 0.95, 0.5), # neon green
			"accent_warning": Color(1.0, 0.84, 0.2),  # gold
			"accent_danger": Color(1.0, 0.3, 0.35),   # red
			"modal_bg": Color(0.04, 0.05, 0.08, 0.94),# dark modal
			"grid_line": Color(0.15, 0.2, 0.28, 0.6)
		}

func reset_defaults():
	SaveManager.reset_all_settings()
	load_settings()
