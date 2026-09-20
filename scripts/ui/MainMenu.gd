extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var theme_btn: Button = $TopBar/ThemeButton

@onready var title_lbl: Label = $CenterContainer/VBoxContainer/Title
@onready var subtitle_lbl: Label = $CenterContainer/VBoxContainer/Subtitle

@onready var play_btn: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var high_scores_btn: Button = $CenterContainer/VBoxContainer/HighScoresButton
@onready var settings_btn: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var exit_btn: Button = $CenterContainer/VBoxContainer/ExitButton

@onready var update_banner: Button = $CenterContainer/VBoxContainer/UpdateBanner
@onready var update_modal: Control = $UpdateModal
@onready var modal_card: VBoxContainer = $UpdateModal/CenterContainer/VBox
@onready var version_label: Label = $UpdateModal/CenterContainer/VBox/VersionLabel
@onready var notes_label: Label = $UpdateModal/CenterContainer/VBox/NotesLabel
@onready var update_now_btn: Button = $UpdateModal/CenterContainer/VBox/BtnHBox/UpdateNowButton
@onready var later_btn: Button = $UpdateModal/CenterContainer/VBox/BtnHBox/LaterButton

func _ready():
	SettingsManager.theme_changed.connect(func(_th): _apply_palette())

	if theme_btn:
		theme_btn.pressed.connect(func():
			SettingsManager.toggle_theme()
			_apply_palette()
		)

	if play_btn:
		play_btn.pressed.connect(func(): GameManager.go_to_game_select())
	if high_scores_btn:
		high_scores_btn.pressed.connect(func(): GameManager.go_to_high_scores())
	if settings_btn:
		settings_btn.pressed.connect(func(): GameManager.go_to_settings())
	if exit_btn:
		exit_btn.pressed.connect(func(): get_tree().quit())

	# Update Notifier wiring
	if update_banner:
		update_banner.pressed.connect(func(): update_modal.visible = true)
	if update_now_btn:
		update_now_btn.pressed.connect(func():
			UpdateManager.open_download_page()
			update_modal.visible = false
		)
	if later_btn:
		later_btn.pressed.connect(func(): update_modal.visible = false)

	UpdateManager.update_available.connect(_on_update_available)
	if UpdateManager.is_update_available:
		_show_update_prompt(UpdateManager.latest_version, UpdateManager.release_notes)
	else:
		UpdateManager.check_for_updates()

	_apply_palette()

func _apply_palette():
	var pal = SettingsManager.get_palette()
	if color_rect:
		color_rect.color = pal["bg"]

	if theme_btn:
		if SettingsManager.is_light_theme():
			theme_btn.text = "☀️ LIGHT"
			theme_btn.modulate = Color(0.95, 0.65, 0.05)
		else:
			theme_btn.text = "🌙 DARK"
			theme_btn.modulate = Color(0.4, 0.75, 1.0)

	if title_lbl:
		title_lbl.modulate = pal["text_primary"]
	if subtitle_lbl:
		subtitle_lbl.modulate = pal["accent_warning"]

	# Style buttons
	var buttons = [play_btn, high_scores_btn, settings_btn, exit_btn]
	for b in buttons:
		if b:
			_style_menu_button(b, pal)

	if update_modal:
		var modal_rect = update_modal as ColorRect
		modal_rect.color = pal["modal_bg"]

func _style_menu_button(btn: Button, pal: Dictionary):
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.bg_color = pal["card_bg"]
	style.border_color = pal["card_border"]
	style.set_border_width_all(1.5)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", pal["text_primary"])
	btn.add_theme_color_override("font_hover_color", pal["text_accent"])
	btn.add_theme_color_override("font_pressed_color", pal["accent_btn"])

func _on_update_available(tag: String, _url: String, notes: String):
	_show_update_prompt(tag, notes)

func _show_update_prompt(tag: String, notes: String):
	if update_banner:
		update_banner.text = "✨ NEW UPDATE AVAILABLE: %s" % tag
		update_banner.visible = true
	if version_label:
		version_label.text = "Version %s is ready to install!" % tag
	if notes_label and notes != "":
		notes_label.text = notes.strip_edges().left(140)
	if update_modal:
		update_modal.visible = true
