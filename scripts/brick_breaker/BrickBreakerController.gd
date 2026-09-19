extends Node2D

const BALL_SCENE = preload("res://scenes/brick_breaker/Ball.tscn")
const BRICK_SCENE = preload("res://scenes/brick_breaker/Brick.tscn")
const POWERUP_SCENE = preload("res://scenes/brick_breaker/PowerUp.tscn")
const LevelData = preload("res://scripts/brick_breaker/LevelData.gd")

var current_level_idx: int = 1
var max_levels: int = 5
var score: int = 0
var lives: int = 3
var high_score: int = 0
var combo_count: int = 0

var is_game_over: bool = false
var is_paused: bool = false
var is_level_cleared: bool = false

var active_balls: Array = []

@onready var paddle: StaticBody2D = $Paddle
@onready var bricks_container: Node2D = $Bricks
@onready var powerups_container: Node2D = $PowerUps
@onready var balls_container: Node2D = $Balls

var current_arena_id: String = "midnight_vault"

# HUD Nodes
@onready var score_label: Label = $HUD/TopBar/ScoreLabel
@onready var level_label: Label = $HUD/TopBar/LevelLabel
@onready var lives_label: Label = $HUD/TopBar/LivesLabel
@onready var customizer_btn: Button = $HUD/TopBar/CustomizerButton
@onready var pause_button: Button = $HUD/TopBar/PauseButton
@onready var customizer_modal: Control = $HUD/CustomizerModal
@onready var launch_prompt: Label = $HUD/LaunchPrompt

# Dialogs
@onready var level_clear_panel: Control = $HUD/LevelClearPanel
@onready var level_clear_title: Label = $HUD/LevelClearPanel/VBox/Title
@onready var next_level_btn: Button = $HUD/LevelClearPanel/VBox/NextButton

@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var game_over_title: Label = $HUD/GameOverPanel/VBox/Title
@onready var final_score_label: Label = $HUD/GameOverPanel/VBox/FinalScoreLabel
@onready var final_best_label: Label = $HUD/GameOverPanel/VBox/FinalBestLabel
@onready var retry_btn: Button = $HUD/GameOverPanel/VBox/BtnContainer/RetryButton
@onready var menu_btn: Button = $HUD/GameOverPanel/VBox/BtnContainer/MenuButton

# Touch Controls
@onready var btn_left: Button = $HUD/TouchControls/LeftButton
@onready var btn_right: Button = $HUD/TouchControls/RightButton
@onready var btn_launch: Button = $HUD/TouchControls/LaunchButton

func _ready():
	high_score = SaveManager.get_high_score("brick_breaker")
	current_arena_id = SaveManager.get_equipped("brick_arena", "midnight_vault")

	_setup_customizer()

	if customizer_btn:
		customizer_btn.pressed.connect(func(): customizer_modal.show_modal())
	pause_button.pressed.connect(_toggle_pause)
	retry_btn.pressed.connect(restart_game)
	menu_btn.pressed.connect(func(): GameManager.go_to_game_select())
	next_level_btn.pressed.connect(_advance_level)

	btn_left.button_down.connect(func(): paddle.set_move_dir(-1.0))
	btn_left.button_up.connect(func(): paddle.set_move_dir(0.0))
	btn_right.button_down.connect(func(): paddle.set_move_dir(1.0))
	btn_right.button_up.connect(func(): paddle.set_move_dir(0.0))
	btn_launch.pressed.connect(_try_launch_ball)

	restart_game()

func _setup_customizer():
	if not customizer_modal:
		return
	var categories = [
		{
			"category_name": "PADDLES",
			"category_key": "brick_paddle",
			"items": [
				{"id": "classic_cyan", "name": "Classic Cyan", "desc": "Balanced neon striker paddle.", "req": "Starter"},
				{"id": "plasma_blade", "name": "Plasma Blade", "desc": "Crimson blade with wide deflection.", "req": "Reach 600 Pts"},
				{"id": "golden_ingot", "name": "Golden Ingot", "desc": "Gilded auric bar with high bounce force.", "req": "Reach 1500 Pts"},
				{"id": "fire_striker", "name": "Fire Striker", "desc": "Blazing solar striker with rapid rebound.", "req": "Reach 3000 Pts"}
			]
		},
		{
			"category_name": "BALLS",
			"category_key": "brick_ball",
			"items": [
				{"id": "silver_sphere", "name": "Silver Sphere", "desc": "Polished chrome steel ball.", "req": "Starter"},
				{"id": "fireball_comet", "name": "Fireball Comet", "desc": "Flaming ember projectile.", "req": "Reach 1000 Pts"},
				{"id": "neon_prism", "name": "Neon Prism", "desc": "Prismatic crystal energy orb.", "req": "Reach 2200 Pts"}
			]
		},
		{
			"category_name": "ARENAS",
			"category_key": "brick_arena",
			"items": [
				{"id": "midnight_vault", "name": "Midnight Vault", "desc": "Dark indigo cyberpunk arena.", "req": "Starter"},
				{"id": "emerald_matrix", "name": "Emerald Matrix", "desc": "Phosphor green arcade grid.", "req": "Reach 800 Pts"},
				{"id": "crimson_chasm", "name": "Crimson Chasm", "desc": "Molten volcanic neon hall.", "req": "Reach 1800 Pts"}
			]
		}
	]
	customizer_modal.setup("BRICK GEAR & ARENAS", categories)
	customizer_modal.item_equipped.connect(func(cat_key, item_id):
		if cat_key == "brick_paddle":
			paddle.apply_skin(item_id)
		elif cat_key == "brick_ball":
			for b in active_balls:
				if is_instance_valid(b) and b.has_method("apply_ball_style"):
					b.apply_ball_style(item_id)
		elif cat_key == "brick_arena":
			current_arena_id = item_id
			queue_redraw()
	)

func restart_game():
	score = 0
	lives = 3
	current_level_idx = 1
	is_game_over = false
	is_level_cleared = false
	game_over_panel.visible = false
	level_clear_panel.visible = false
	load_level(current_level_idx)

func load_level(idx: int):
	current_level_idx = idx
	is_level_cleared = false
	level_clear_panel.visible = false
	game_over_panel.visible = false
	combo_count = 0

	# Clear containers
	for c in bricks_container.get_children(): c.queue_free()
	for c in powerups_container.get_children(): c.queue_free()
	for c in balls_container.get_children(): c.queue_free()
	active_balls.clear()

	paddle.reset()

	# Build Bricks from LevelData
	var data = LevelData.get_level(current_level_idx)
	for b_info in data["bricks"]:
		var brick = BRICK_SCENE.instantiate()
		bricks_container.add_child(brick)
		brick.position = b_info["pos"]
		brick.setup(b_info["type"])
		brick.destroyed.connect(_on_brick_destroyed)

	_spawn_starting_ball()
	_update_hud()

func _spawn_starting_ball():
	var ball = BALL_SCENE.instantiate()
	balls_container.add_child(ball)
	ball.stick_to_paddle(paddle)
	ball.ball_lost.connect(_on_ball_lost)
	active_balls.append(ball)
	launch_prompt.visible = true

func _try_launch_ball():
	for b in active_balls:
		if is_instance_valid(b) and b.is_stuck_to_paddle:
			b.launch()
			launch_prompt.visible = false

func _unhandled_input(event: InputEvent):
	if is_game_over or is_level_cleared:
		return

	if event.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP):
		_try_launch_ball()
	elif (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_try_launch_ball()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause()

func _on_brick_destroyed(pts: int, b_type: int, pos: Vector2):
	combo_count += 1
	var combo_bonus = int(combo_count * 10)
	score += pts + combo_bonus
	_update_hud()
	_check_unlock_milestones()

	# Roll for power-up drop
	if b_type == 2: # Bonus brick -> 100% drop
		_spawn_powerup(pos)
	elif randf() < 0.16: # 16% random drop on other bricks
		_spawn_powerup(pos)

	# Check if all bricks cleared
	await get_tree().process_frame
	if bricks_container.get_child_count() <= 1 and not is_level_cleared:
		_on_level_cleared()

func _spawn_powerup(pos: Vector2):
	var p = POWERUP_SCENE.instantiate()
	powerups_container.add_child(p)
	var roll = randf()
	var type = 0
	if roll < 0.35:
		type = 0 # Wide Paddle
	elif roll < 0.65:
		type = 1 # Multi-Ball
	elif roll < 0.85:
		type = 2 # Slow Ball
	else:
		type = 3 # Extra Life
	p.setup(type, pos)
	p.collected.connect(_on_powerup_collected)

func _on_powerup_collected(type: int):
	match type:
		0: # WIDE
			paddle.set_wide(true)
		1: # MULTI
			_spawn_multi_balls()
		2: # SLOW
			for b in active_balls:
				if is_instance_valid(b): b.set_slow()
		3: # LIFE
			lives = min(5, lives + 1)
			_update_hud()

func _spawn_multi_balls():
	var current_count = active_balls.size()
	for i in range(2):
		if current_count + i < 6:
			var b = BALL_SCENE.instantiate()
			balls_container.add_child(b)
			b.position = paddle.position + Vector2(randf_range(-15, 15), -14)
			var angle = randf_range(deg_to_rad(-60), deg_to_rad(60))
			b.velocity = Vector2(sin(angle), -cos(angle)) * 320.0
			b.is_stuck_to_paddle = false
			b.ball_lost.connect(_on_ball_lost)
			active_balls.append(b)

func _on_ball_lost(ball_node):
	active_balls.erase(ball_node)
	ball_node.queue_free()

	if active_balls.size() == 0:
		lives -= 1
		combo_count = 0
		_update_hud()
		if lives <= 0:
			_game_over()
		else:
			_spawn_starting_ball()

func _on_level_cleared():
	is_level_cleared = true
	score += 500
	_save_high_score()
	_update_hud()

	if current_level_idx >= max_levels:
		level_clear_title.text = "VAULT DESTROYED!\nARCADE CHAMPION!"
		next_level_btn.text = "PLAY AGAIN"
	else:
		level_clear_title.text = "LEVEL %d CLEARED!\n+500 BONUS" % current_level_idx
		next_level_btn.text = "NEXT LEVEL"

	level_clear_panel.visible = true

func _advance_level():
	if current_level_idx >= max_levels:
		restart_game()
	else:
		load_level(current_level_idx + 1)

func _game_over():
	is_game_over = true
	_save_high_score()
	launch_prompt.visible = false
	final_score_label.text = "FINAL SCORE: %d" % score
	final_best_label.text = "BEST RECORD: %d" % high_score
	game_over_panel.visible = true

func _save_high_score():
	if score > high_score:
		high_score = score
		SaveManager.set_high_score("brick_breaker", high_score)

func _update_hud():
	score_label.text = "%05d" % score
	level_label.text = "LVL %d/5" % current_level_idx
	var hearts = ""
	for i in range(lives): hearts += "♥ "
	lives_label.text = hearts.strip_edges()

func _toggle_pause():
	if is_game_over:
		return
	var overlay = GameManager.open_pause_overlay($HUD)
	if overlay:
		is_paused = true
		for b in active_balls:
			if is_instance_valid(b):
				b.set_physics_process(false)
		overlay.tree_exiting.connect(func():
			is_paused = false
			for b in active_balls:
				if is_instance_valid(b):
					b.set_physics_process(true)
		)

func _check_unlock_milestones():
	if score >= 600:
		SaveManager.unlock("brick_paddle", "plasma_blade", "Plasma Blade")
	if score >= 800:
		SaveManager.unlock("brick_arena", "emerald_matrix", "Emerald Matrix")
	if score >= 1000:
		SaveManager.unlock("brick_ball", "fireball_comet", "Fireball Comet")
	if score >= 1500:
		SaveManager.unlock("brick_paddle", "golden_ingot", "Golden Ingot")
	if score >= 1800:
		SaveManager.unlock("brick_arena", "crimson_chasm", "Crimson Chasm")
	if score >= 2200:
		SaveManager.unlock("brick_ball", "neon_prism", "Neon Prism")
	if score >= 3000:
		SaveManager.unlock("brick_paddle", "fire_striker", "Fire Striker")

func _draw():
	var wall_color = Color("1e293b")
	var border_color = Color("38bdf8")

	match current_arena_id:
		"emerald_matrix":
			wall_color = Color(0.04, 0.12, 0.08)
			border_color = Color(0.1, 0.85, 0.45)
		"crimson_chasm":
			wall_color = Color(0.15, 0.04, 0.05)
			border_color = Color(1.0, 0.25, 0.3)
		_: # midnight_vault
			wall_color = Color("1e293b")
			border_color = Color("38bdf8")

	# Top Wall
	draw_rect(Rect2(0, 0, 360, 42), wall_color)
	draw_line(Vector2(0, 42), Vector2(360, 42), border_color, 2.0)

	# Left Wall
	draw_rect(Rect2(0, 42, 12, 600), wall_color)
	draw_line(Vector2(12, 42), Vector2(12, 640), border_color, 2.0)

	# Right Wall
	draw_rect(Rect2(348, 42, 12, 600), wall_color)
	draw_line(Vector2(348, 42), Vector2(348, 640), border_color, 2.0)
