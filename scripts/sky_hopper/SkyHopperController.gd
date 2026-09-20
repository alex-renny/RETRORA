extends Node2D

const PIPE_SCENE = preload("res://scenes/sky_hopper/PipePair.tscn")

const BASE_SPEED: float = 140.0
const MAX_SPEED: float = 240.0
const BASE_GAP: float = 160.0
const MIN_GAP: float = 132.0

enum State { READY, PLAYING, GAMEOVER, PAUSED }
var current_state: State = State.READY

var score: int = 0
var high_score: int = 0
var current_speed: float = BASE_SPEED
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0

# Background scrolling
var ground_scroll: float = 0.0
var hill_scroll: float = 0.0

# Screen Shake
var shake_intensity: float = 0.0

@onready var player: CharacterBody2D = $Player
@onready var pipe_container: Node2D = $PipeContainer
@onready var camera: Camera2D = $Camera2D

# UI Nodes
@onready var hud: CanvasLayer = $HUD
@onready var score_label: Label = $HUD/ScoreLabel
@onready var ready_prompt: VBoxContainer = $HUD/ReadyPrompt
@onready var bird_button: Button = $HUD/BirdButton
@onready var pause_button: Button = $HUD/PauseButton
@onready var customizer_modal: Control = $HUD/CustomizerModal
@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var final_score_label: Label = $HUD/GameOverPanel/VBox/FinalScoreLabel
@onready var final_best_label: Label = $HUD/GameOverPanel/VBox/FinalBestLabel
@onready var new_record_label: Label = $HUD/GameOverPanel/VBox/NewRecordLabel
@onready var retry_button: Button = $HUD/GameOverPanel/VBox/BtnContainer/RetryButton
@onready var menu_button: Button = $HUD/GameOverPanel/VBox/BtnContainer/MenuButton

func _ready():
	high_score = SaveManager.get_high_score("sky_hopper")
	player.add_to_group("player")
	player.crashed.connect(_on_player_crashed)

	SettingsManager.theme_changed.connect(func(_thm): _apply_theme())
	_apply_theme()

	_setup_customizer()

	if bird_button:
		bird_button.pressed.connect(func(): customizer_modal.show_modal())
	pause_button.pressed.connect(_toggle_pause)
	retry_button.pressed.connect(reset_game)
	menu_button.pressed.connect(func(): GameManager.go_to_game_select())

	var btn_container = get_node_or_null("HUD/GameOverPanel/VBox/BtnContainer")
	if btn_container and not btn_container.has_node("UnlocksButton"):
		var u_btn = Button.new()
		u_btn.name = "UnlocksButton"
		u_btn.text = "🎨"
		u_btn.custom_minimum_size = Vector2(44, 40)
		u_btn.modulate = Color(1.0, 0.88, 0.25)
		u_btn.pressed.connect(func(): customizer_modal.show_modal())
		btn_container.add_child(u_btn)
		if btn_container.get_child_count() > 2:
			btn_container.move_child(u_btn, 1)

	reset_game()

func _apply_theme():
	var p = SettingsManager.get_palette()
	score_label.add_theme_color_override("font_color", p["text_primary"])
	queue_redraw()

func _setup_customizer():
	if not customizer_modal:
		return
	var cdata = GameRegistry.get_customizer_data("sky_hopper")
	customizer_modal.setup(cdata.get("title", "BIRD ROSTER"), cdata.get("categories", []))
	customizer_modal.item_equipped.connect(func(cat_key, item_id):
		if cat_key == "hopper_bird":
			player.apply_bird(item_id)
	)

func reset_game():
	current_state = State.READY
	score = 0
	current_speed = BASE_SPEED
	spawn_timer = 1.0
	score_label.text = "0"
	ready_prompt.visible = true
	game_over_panel.visible = false

	# Clear pipes
	for child in pipe_container.get_children():
		child.queue_free()

	player.reset()

func start_playing():
	current_state = State.PLAYING
	ready_prompt.visible = false
	player.start_flying()

func _unhandled_input(event: InputEvent):
	if current_state == State.READY:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			start_playing()
	elif current_state == State.PLAYING:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			player.jump()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_toggle_pause()

func _process(delta: float):
	if current_state == State.READY:
		# Gentle bobbing animation while waiting
		player.position.y = 280.0 + sin(Time.get_ticks_msec() * 0.005) * 8.0
		_scroll_scenery(delta * 40.0)
		return

	if current_state != State.PLAYING:
		_process_shake(delta)
		return

	_scroll_scenery(delta * current_speed)
	_process_shake(delta)

	# Pipe Spawner
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		_spawn_pipe()

func _scroll_scenery(amount: float):
	ground_scroll = fmod(ground_scroll + amount, 24.0)
	hill_scroll = fmod(hill_scroll + amount * 0.3, 360.0)
	queue_redraw()

func _spawn_pipe():
	var pipe = PIPE_SCENE.instantiate()
	pipe_container.add_child(pipe)
	pipe.position.x = 420.0 # Spawn just off right edge

	# Calculate dynamic gap
	var gap = max(MIN_GAP, BASE_GAP - (score / 10.0) * 8.0)
	var gap_y = randf_range(160.0, 420.0)

	pipe.setup(gap_y, gap, current_speed)
	pipe.passed_pipe.connect(_on_passed_pipe)
	pipe.hit_player.connect(func(): player.die())

func _on_passed_pipe():
	if current_state != State.PLAYING:
		return
	score += 1
	score_label.text = str(score)

	_check_unlock_milestones()

	# Ramp difficulty every 5 points
	current_speed = min(MAX_SPEED, BASE_SPEED + (score / 5.0) * 5.0)
	spawn_interval = max(1.4, 2.0 - (current_speed - BASE_SPEED) / 200.0)

func _check_unlock_milestones():
	if score >= 10:
		SaveManager.unlock("hopper_bird", "blue_falcon", "Blue Falcon")
	if score >= 25:
		SaveManager.unlock("hopper_bird", "cyber_drone", "Cyber Drone")
	if score >= 50:
		SaveManager.unlock("hopper_bird", "pixel_phoenix", "Pixel Phoenix")
	if score >= 80:
		SaveManager.unlock("hopper_bird", "midnight_bat", "Midnight Bat")

func _on_player_crashed():
	current_state = State.GAMEOVER
	shake_intensity = 12.0

	var is_new_record = false
	if score > high_score:
		high_score = score
		SaveManager.set_high_score("sky_hopper", high_score)
		is_new_record = true

	final_score_label.text = "SCORE: %d" % score
	final_best_label.text = "BEST: %d" % high_score
	new_record_label.visible = is_new_record
	game_over_panel.visible = true

func _toggle_pause():
	if current_state == State.GAMEOVER:
		return
	var overlay = GameManager.open_pause_overlay($HUD)
	if overlay:
		current_state = State.PAUSED
		overlay.tree_exiting.connect(func():
			if current_state == State.PAUSED:
				current_state = State.PLAYING
		)

func _process_shake(delta: float):
	if shake_intensity > 0.0:
		shake_intensity = max(0.0, shake_intensity - 18.0 * delta)
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		camera.offset = Vector2.ZERO

func _draw():
	var is_light = SettingsManager.is_light_theme()
	
	# 1. Sky Gradient Background
	var sky_top = Color(0.24, 0.65, 0.95) if is_light else Color("142230")
	var sky_bottom = Color(0.68, 0.88, 0.98) if is_light else Color("234b6e")
	draw_rect(Rect2(0, 0, 360, 570), sky_bottom)
	draw_rect(Rect2(0, 0, 360, 260), sky_top)

	# Fluffy drifting clouds in light theme
	if is_light:
		var c_col = Color(1.0, 1.0, 1.0, 0.75)
		var c1_x = fmod(hill_scroll * 1.5 + 40.0, 420.0) - 60.0
		var c2_x = fmod(hill_scroll * 1.2 + 240.0, 420.0) - 60.0
		draw_circle(Vector2(c1_x, 80), 22, c_col)
		draw_circle(Vector2(c1_x + 18, 76), 28, c_col)
		draw_circle(Vector2(c1_x + 36, 82), 20, c_col)
		draw_circle(Vector2(c2_x, 140), 18, c_col)
		draw_circle(Vector2(c2_x + 16, 136), 24, c_col)
		draw_circle(Vector2(c2_x + 32, 142), 16, c_col)

	# 2. Distant Retro Hills
	var hill_col = Color(0.35, 0.78, 0.45) if is_light else Color("11281c")
	var hill_hl = Color(0.48, 0.88, 0.55) if is_light else Color("193828")
	draw_circle(Vector2(100 - hill_scroll, 580), 140, hill_col)
	draw_circle(Vector2(95 - hill_scroll, 570), 90, hill_hl)
	draw_circle(Vector2(280 - hill_scroll, 580), 120, hill_col)
	draw_circle(Vector2(275 - hill_scroll, 572), 80, hill_hl)
	draw_circle(Vector2(460 - hill_scroll, 580), 150, hill_col)
	draw_circle(Vector2(640 - hill_scroll, 580), 130, hill_col)

	# 3. Ground (Y = 570 to 640)
	var dirt_col = Color(0.78, 0.52, 0.28) if is_light else Color("5c3a21")
	var grass_col = Color(0.22, 0.76, 0.28) if is_light else Color("38761d")
	var dark_grass = Color(0.16, 0.62, 0.22) if is_light else Color("274e13")

	draw_rect(Rect2(0, 570, 360, 70), dirt_col)
	draw_rect(Rect2(0, 570, 360, 10), grass_col)

	# Striped grass edge
	var gx = -ground_scroll
	while gx < 360.0:
		draw_rect(Rect2(gx, 570, 12, 10), dark_grass)
		gx += 24.0
