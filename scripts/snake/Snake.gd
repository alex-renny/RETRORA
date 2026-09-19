extends Node2D

const GRID_COLS = 20
const GRID_ROWS = 20
const CELL_SIZE = 16.0
const GRID_ORIGIN = Vector2(20.0, 80.0) # 320x320 area centered on 360x640

const BASE_TICK_INTERVAL: float = 0.18
const MIN_TICK_INTERVAL: float = 0.07
const SPEED_RAMP: float = 0.97

enum State { READY, PLAYING, GAMEOVER, PAUSED }
var current_state: State = State.READY

var tick_interval: float = BASE_TICK_INTERVAL
var timer: float = 0.0
var direction: Vector2i = Vector2i(1, 0) # start moving right
var pending_direction: Vector2i = direction
var snake: Array[Vector2i] = []
var food_pos: Vector2i = Vector2i(15, 10)
var score: int = 0
var high_score: int = 0

# Swipe detection
var touch_start_pos: Vector2 = Vector2.ZERO
var min_swipe_dist: float = 25.0

@onready var score_label: Label = $HUD/TopBar/ScoreLabel
@onready var best_label: Label = $HUD/TopBar/BestLabel
@onready var pause_button: Button = $HUD/TopBar/PauseButton
@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var final_score_label: Label = $HUD/GameOverPanel/VBox/FinalScoreLabel
@onready var final_best_label: Label = $HUD/GameOverPanel/VBox/FinalBestLabel
@onready var new_record_label: Label = $HUD/GameOverPanel/VBox/NewRecordLabel
@onready var retry_button: Button = $HUD/GameOverPanel/VBox/BtnContainer/RetryButton
@onready var menu_button: Button = $HUD/GameOverPanel/VBox/BtnContainer/MenuButton

# D-Pad buttons
@onready var btn_up: Button = $HUD/DPad/BtnUp
@onready var btn_down: Button = $HUD/DPad/BtnDown
@onready var btn_left: Button = $HUD/DPad/BtnLeft
@onready var btn_right: Button = $HUD/DPad/BtnRight

func _ready():
	high_score = SaveManager.get_high_score("snake")
	best_label.text = "BEST: %d" % high_score

	pause_button.pressed.connect(_toggle_pause)
	retry_button.pressed.connect(start_game)
	menu_button.pressed.connect(func(): GameManager.go_to_main_menu())

	btn_up.pressed.connect(func(): _set_direction(Vector2i(0, -1)))
	btn_down.pressed.connect(func(): _set_direction(Vector2i(0, 1)))
	btn_left.pressed.connect(func(): _set_direction(Vector2i(-1, 0)))
	btn_right.pressed.connect(func(): _set_direction(Vector2i(1, 0)))

	start_game()

func start_game():
	snake.clear()
	var center = Vector2i(GRID_COLS / 2, GRID_ROWS / 2)
	snake.append(center)
	snake.append(center - Vector2i(1, 0))
	snake.append(center - Vector2i(2, 0))

	direction = Vector2i(1, 0)
	pending_direction = direction
	score = 0
	tick_interval = BASE_TICK_INTERVAL
	timer = 0.0
	current_state = State.PLAYING

	_update_hud()
	game_over_panel.visible = false
	_spawn_food()
	queue_redraw()

func _update_hud():
	score_label.text = "SCORE: %d" % score
	best_label.text = "BEST: %d" % high_score

func _spawn_food():
	var open_cells: Array[Vector2i] = []
	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			var cell = Vector2i(x, y)
			if not snake.has(cell):
				open_cells.append(cell)

	if open_cells.size() > 0:
		food_pos = open_cells[randi() % open_cells.size()]
	else:
		_game_over() # Max possible score reached!

func _set_direction(new_dir: Vector2i):
	if current_state != State.PLAYING:
		return
	# Prevent 180-degree instant reversal
	if new_dir != -direction:
		pending_direction = new_dir

func _unhandled_input(event: InputEvent):
	if current_state != State.PLAYING:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP or event.keycode == KEY_W:
			_set_direction(Vector2i(0, -1))
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			_set_direction(Vector2i(0, 1))
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_set_direction(Vector2i(-1, 0))
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_set_direction(Vector2i(1, 0))
		elif event.keycode == KEY_ESCAPE:
			_toggle_pause()

	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
		else:
			var diff = event.position - touch_start_pos
			if diff.length() >= min_swipe_dist:
				if abs(diff.x) > abs(diff.y):
					if diff.x > 0:
						_set_direction(Vector2i(1, 0))
					else:
						_set_direction(Vector2i(-1, 0))
				else:
					if diff.y > 0:
						_set_direction(Vector2i(0, 1))
					else:
						_set_direction(Vector2i(0, -1))

func _process(delta: float):
	if current_state != State.PLAYING:
		return

	timer += delta
	if timer >= tick_interval:
		timer = 0.0
		_move_snake()

func _move_snake():
	direction = pending_direction
	var head = snake[0] + direction

	# Wall collision
	if head.x < 0 or head.x >= GRID_COLS or head.y < 0 or head.y >= GRID_ROWS:
		_game_over()
		return

	# Self collision
	if snake.has(head):
		_game_over()
		return

	snake.insert(0, head)

	if head == food_pos:
		score += 1
		tick_interval = max(MIN_TICK_INTERVAL, tick_interval * SPEED_RAMP)
		_update_hud()
		_spawn_food()
	else:
		snake.pop_back()

	queue_redraw()

func _game_over():
	current_state = State.GAMEOVER
	var is_new_record = false
	if score > high_score:
		high_score = score
		SaveManager.set_high_score("snake", high_score)
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

func _draw():
	# 1. Background arena
	var arena_rect = Rect2(GRID_ORIGIN, Vector2(GRID_COLS * CELL_SIZE, GRID_ROWS * CELL_SIZE))
	draw_rect(arena_rect, Color(0.08, 0.12, 0.08))
	draw_rect(arena_rect, Color(0.3, 0.6, 0.3), false, 2.0)

	# 2. Food (Bright red/apple with green leaf dot)
	var food_screen_pos = GRID_ORIGIN + Vector2(food_pos) * CELL_SIZE
	draw_rect(Rect2(food_screen_pos + Vector2(2, 2), Vector2(CELL_SIZE - 4, CELL_SIZE - 4)), Color(0.95, 0.2, 0.2))
	draw_rect(Rect2(food_screen_pos + Vector2(6, 1), Vector2(4, 3)), Color(0.3, 0.85, 0.3))

	# 3. Snake Body
	for i in range(snake.size()):
		var part = snake[i]
		var screen_pos = GRID_ORIGIN + Vector2(part) * CELL_SIZE
		var rect = Rect2(screen_pos + Vector2(1, 1), Vector2(CELL_SIZE - 2, CELL_SIZE - 2))

		if i == 0:
			# Head (Bright green with dark pixel eyes)
			draw_rect(rect, Color(0.4, 0.9, 0.3))
			var eye_color = Color(0.05, 0.1, 0.05)
			if direction == Vector2i(1, 0): # Facing right
				draw_rect(Rect2(screen_pos + Vector2(10, 3), Vector2(2, 2)), eye_color)
				draw_rect(Rect2(screen_pos + Vector2(10, 11), Vector2(2, 2)), eye_color)
			elif direction == Vector2i(-1, 0): # Facing left
				draw_rect(Rect2(screen_pos + Vector2(4, 3), Vector2(2, 2)), eye_color)
				draw_rect(Rect2(screen_pos + Vector2(4, 11), Vector2(2, 2)), eye_color)
			elif direction == Vector2i(0, -1): # Facing up
				draw_rect(Rect2(screen_pos + Vector2(3, 4), Vector2(2, 2)), eye_color)
				draw_rect(Rect2(screen_pos + Vector2(11, 4), Vector2(2, 2)), eye_color)
			elif direction == Vector2i(0, 1): # Facing down
				draw_rect(Rect2(screen_pos + Vector2(3, 10), Vector2(2, 2)), eye_color)
				draw_rect(Rect2(screen_pos + Vector2(11, 10), Vector2(2, 2)), eye_color)
		else:
			# Body (Slightly darker green with subtle checker/shade)
			var body_col = Color(0.25, 0.75, 0.25) if i % 2 == 0 else Color(0.2, 0.65, 0.2)
			draw_rect(rect, body_col)
