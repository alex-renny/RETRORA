extends Control

@onready var play_btn: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var high_scores_btn: Button = $CenterContainer/VBoxContainer/HighScoresButton
@onready var settings_btn: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var exit_btn: Button = $CenterContainer/VBoxContainer/ExitButton

@onready var update_banner: Button = $CenterContainer/VBoxContainer/UpdateBanner
@onready var update_modal: Control = $UpdateModal
@onready var version_label: Label = $UpdateModal/CenterContainer/VBox/VersionLabel
@onready var notes_label: Label = $UpdateModal/CenterContainer/VBox/NotesLabel
@onready var update_now_btn: Button = $UpdateModal/CenterContainer/VBox/BtnHBox/UpdateNowButton
@onready var later_btn: Button = $UpdateModal/CenterContainer/VBox/BtnHBox/LaterButton

func _ready():
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
