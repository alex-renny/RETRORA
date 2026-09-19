extends Control

@onready var play_btn: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var high_scores_btn: Button = $CenterContainer/VBoxContainer/HighScoresButton
@onready var settings_btn: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var exit_btn: Button = $CenterContainer/VBoxContainer/ExitButton

func _ready():
	if play_btn:
		play_btn.pressed.connect(func(): GameManager.go_to_game_select())
	if high_scores_btn:
		high_scores_btn.pressed.connect(func(): GameManager.go_to_high_scores())
	if settings_btn:
		settings_btn.pressed.connect(func(): GameManager.go_to_settings())
	if exit_btn:
		exit_btn.pressed.connect(func(): get_tree().quit())
