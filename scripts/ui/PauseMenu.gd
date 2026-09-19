extends Control

@onready var resume_btn: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var restart_btn: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var settings_btn: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var menu_btn: Button = $CenterContainer/VBoxContainer/MenuButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	settings_btn.pressed.connect(func():
		get_tree().paused = false
		GameManager.go_to_settings()
	)
	menu_btn.pressed.connect(func():
		get_tree().paused = false
		GameManager.go_to_game_select()
	)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_resume()
		get_viewport().set_input_as_handled()

func _on_resume():
	get_tree().paused = false
	if get_parent() != null and get_parent() != get_tree().root:
		queue_free()
	else:
		var last_game = GameManager.selected_game_id
		if last_game != "" and GameRegistry.games.has(last_game):
			GameManager.change_scene(GameRegistry.get_game(last_game).get("scene", ""))
		else:
			GameManager.go_to_game_select()

func _on_restart():
	get_tree().paused = false
	if get_parent() != null and get_parent() != get_tree().root:
		queue_free()
		get_tree().reload_current_scene()
	else:
		var last_game = GameManager.selected_game_id
		if last_game != "" and GameRegistry.games.has(last_game):
			GameManager.change_scene(GameRegistry.get_game(last_game).get("scene", ""))
		else:
			GameManager.go_to_game_select()
