extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var title_lbl: Label = $CenterContainer/VBoxContainer/Title

@onready var btn_theme: Button = $CenterContainer/VBoxContainer/ThemeRow/BtnTheme
@onready var btn_sound: Button = $CenterContainer/VBoxContainer/SoundRow/BtnSound
@onready var btn_music: Button = $CenterContainer/VBoxContainer/MusicRow/BtnMusic
@onready var btn_shake: Button = $CenterContainer/VBoxContainer/ShakeRow/BtnShake
@onready var btn_vib: Button = $CenterContainer/VBoxContainer/VibRow/BtnVib
@onready var btn_crt: Button = $CenterContainer/VBoxContainer/CRTRow/BtnCRT

@onready var btn_reset_scores: Button = $CenterContainer/VBoxContainer/ResetScoresButton
@onready var btn_reset_settings: Button = $CenterContainer/VBoxContainer/ResetSettingsButton
@onready var btn_back: Button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	SettingsManager.theme_changed.connect(func(_th): _apply_palette())

	btn_theme.pressed.connect(func():
		SettingsManager.toggle_theme()
		_refresh_ui()
	)
	btn_sound.pressed.connect(func():
		SettingsManager.set_sound(not SettingsManager.sound_enabled)
		_refresh_ui()
	)
	btn_music.pressed.connect(func():
		SettingsManager.set_music(not SettingsManager.music_enabled)
		_refresh_ui()
	)
	btn_shake.pressed.connect(func():
		SettingsManager.set_screen_shake(not SettingsManager.screen_shake_enabled)
		_refresh_ui()
	)
	btn_vib.pressed.connect(func():
		SettingsManager.set_vibration(not SettingsManager.vibration_enabled)
		_refresh_ui()
	)
	btn_crt.pressed.connect(func():
		SettingsManager.set_crt_filter(not SettingsManager.crt_filter_enabled)
		_refresh_ui()
	)

	btn_reset_scores.pressed.connect(func():
		SaveManager.reset_all_high_scores()
		btn_reset_scores.text = "SCORES RESET!"
		await get_tree().create_timer(1.2).timeout
		btn_reset_scores.text = "RESET HIGH SCORES"
	)

	btn_reset_settings.pressed.connect(func():
		SettingsManager.reset_defaults()
		_refresh_ui()
	)

	btn_back.pressed.connect(func():
		GameManager.go_to_main_menu()
	)

	_refresh_ui()

func _refresh_ui():
	_apply_palette()
	if SettingsManager.is_light_theme():
		btn_theme.text = "☀️ LIGHT"
		btn_theme.modulate = Color(0.95, 0.65, 0.05)
	else:
		btn_theme.text = "🌙 DARK"
		btn_theme.modulate = Color(0.4, 0.75, 1.0)

	_set_toggle_style(btn_sound, SettingsManager.sound_enabled)
	_set_toggle_style(btn_music, SettingsManager.music_enabled)
	_set_toggle_style(btn_shake, SettingsManager.screen_shake_enabled)
	_set_toggle_style(btn_vib, SettingsManager.vibration_enabled)
	_set_toggle_style(btn_crt, SettingsManager.crt_filter_enabled)

func _apply_palette():
	var pal = SettingsManager.get_palette()
	if color_rect:
		color_rect.color = pal["bg"]
	if title_lbl:
		title_lbl.modulate = pal["text_primary"]

	# Update all row labels
	var vbox = $CenterContainer/VBoxContainer
	for child in vbox.get_children():
		if child is HBoxContainer:
			var lbl = child.get_node_or_null("Label")
			if lbl:
				lbl.modulate = pal["text_primary"]

func _set_toggle_style(btn: Button, enabled: bool):
	if enabled:
		btn.text = "ON"
		btn.modulate = Color(0.1, 0.8, 0.45)
	else:
		btn.text = "OFF"
		btn.modulate = Color(0.55, 0.55, 0.6)
