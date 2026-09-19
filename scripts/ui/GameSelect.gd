extends Control

@onready var game_list: VBoxContainer = $CenterContainer/VBoxContainer/GameList
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	back_button.pressed.connect(func(): GameManager.go_to_main_menu())
	_populate_games()

func _populate_games():
	for child in game_list.get_children():
		child.queue_free()

	for game_id in GameRegistry.list_games():
		var info = GameRegistry.get_game(game_id)
		var btn = Button.new()
		var high_score = SaveManager.get_high_score(info.get("high_score_key", game_id))
		var status = info.get("status", "")
		
		if status == "PLAYABLE":
			btn.text = "%s  ▶  (BEST: %d)" % [info.get("title", game_id), high_score]
		else:
			btn.text = "%s  [COMING SOON]" % info.get("title", game_id)
			
		btn.custom_minimum_size = Vector2(280, 42)
		var gid = game_id
		var scene_path = info.get("scene", "")
		btn.pressed.connect(func(): 
			GameManager.selected_game_id = gid
			GameManager.change_scene(scene_path)
		)
		game_list.add_child(btn)
