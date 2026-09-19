extends Control

@onready var game_list: VBoxContainer = $CenterContainer/VBoxContainer/GameList
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton
@onready var customizer_modal: Control = $CustomizerModal

func _ready():
	back_button.pressed.connect(func(): GameManager.go_to_main_menu())
	_populate_games()

func _populate_games():
	for child in game_list.get_children():
		child.queue_free()

	for game_id in GameRegistry.list_games():
		var info = GameRegistry.get_game(game_id)
		var high_score = SaveManager.get_high_score(info.get("high_score_key", game_id))
		var status = info.get("status", "")
		var gid = game_id
		var scene_path = info.get("scene", "")

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var play_btn = Button.new()
		if status == "PLAYABLE":
			play_btn.text = "%s  ▶  (BEST: %d)" % [info.get("title", game_id), high_score]
		else:
			play_btn.text = "%s  [COMING SOON]" % info.get("title", game_id)
			play_btn.disabled = true

		play_btn.custom_minimum_size = Vector2(230, 42)
		play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if status == "PLAYABLE":
			play_btn.pressed.connect(func(): 
				GameManager.selected_game_id = gid
				GameManager.change_scene(scene_path)
			)
		row.add_child(play_btn)

		if status == "PLAYABLE":
			var unlock_btn = Button.new()
			unlock_btn.text = "🎨"
			unlock_btn.tooltip_text = "View Skins, Grounds & Unlocks"
			unlock_btn.custom_minimum_size = Vector2(44, 42)
			unlock_btn.modulate = Color(1.0, 0.88, 0.25)
			unlock_btn.pressed.connect(func():
				var cdata = GameRegistry.get_customizer_data(gid)
				customizer_modal.setup(cdata.get("title", "UNLOCKS"), cdata.get("categories", []), "BACK TO SELECT")
				customizer_modal.show_modal()
			)
			row.add_child(unlock_btn)

		game_list.add_child(row)
