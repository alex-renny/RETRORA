extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/Title
@onready var desc_label: Label = $CenterContainer/VBoxContainer/Description
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	back_button.pressed.connect(func(): GameManager.go_to_game_select())
	var current_id = GameManager.selected_game_id
	if current_id != "" and GameRegistry.games.has(current_id):
		var info = GameRegistry.get_game(current_id)
		title_label.text = info.get("title", "ARCADE GAME")
		desc_label.text = info.get("description", "Coming soon to RETRORA!")
	else:
		title_label.text = "COMING SOON"
		desc_label.text = "This arcade game is under development."
