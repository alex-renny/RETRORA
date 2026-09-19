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
@onready var skin_button: Button = $HUD/TopBar/SkinButton
@onready var pause_button: Button = $HUD/TopBar/PauseButton
@onready var customizer_modal: Control = $HUD/CustomizerModal
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

var current_skin_id: String = "classic_green"
var current_arena_id: String = "classic_field"

const SKIN_DATA = {
	"classic_green": {
		"head": Color(0.4, 0.9, 0.3),
		"b1": Color(0.25, 0.75, 0.25),
		"b2": Color(0.2, 0.65, 0.2),
		"eye": Color(0.05, 0.1, 0.05)
	},
	"neon_viper": {
		"head": Color(0.0, 1.0, 0.9),
		"b1": Color(0.0, 0.7, 1.0),
		"b2": Color(0.85, 0.1, 1.0),
		"eye": Color(1.0, 1.0, 1.0)
	},
	"desert_cobra": {
		"head": Color(1.0, 0.75, 0.2),
		"b1": Color(0.85, 0.55, 0.15),
		"b2": Color(0.7, 0.45, 0.1),
		"eye": Color(0.9, 0.1, 0.1)
	},
	"cyber_dragon": {
		"head": Color(1.0, 0.2, 0.3),
		"b1": Color(0.9, 0.1, 0.15),
		"b2": Color(1.0, 0.7, 0.1),
		"eye": Color(0.2, 1.0, 0.8)
	},
	"shadow_wyrm": {
		"head": Color(0.65, 0.3, 0.95),
		"b1": Color(0.3, 0.12, 0.45),
		"b2": Color(0.18, 0.08, 0.3),
		"eye": Color(0.9, 0.2, 0.9)
	}
}

const ARENA_DATA = {
	"classic_field": {
		"bg": Color(0.08, 0.12, 0.08),
		"border": Color(0.3, 0.6, 0.3),
		"grid": Color(0.12, 0.18, 0.12)
	},
	"synthwave_grid": {
		"bg": Color(0.07, 0.04, 0.13),
		"border": Color(0.95, 0.2, 0.85),
		"grid": Color(0.2, 0.1, 0.35)
	},
	"desert_dunes": {
		"bg": Color(0.18, 0.13, 0.07),
		"border": Color(0.9, 0.65, 0.2),
		"grid": Color(0.28, 0.2, 0.12)
	},
	"frozen_tundra": {
		"bg": Color(0.05, 0.1, 0.16),
		"border": Color(0.4, 0.85, 1.0),
		"grid": Color(0.1, 0.2, 0.3)
	},
	"volcanic_abyss": {
		"bg": Color(0.13, 0.03, 0.03),
		"border": Color(1.0, 0.35, 0.1),
		"grid": Color(0.25, 0.08, 0.06)
	}
}

func _ready():
	high_score = SaveManager.get_high_score("snake")
	best_label.text = "BEST: %d" % high_score

	current_skin_id = SaveManager.get_equipped("snake_skin", "classic_green")
	current_arena_id = SaveManager.get_equipped("snake_arena", "classic_field")

	_setup_customizer()

	if skin_button:
		skin_button.pressed.connect(func(): customizer_modal.show_modal())
	pause_button.pressed.connect(_toggle_pause)
	retry_button.pressed.connect(start_game)
	menu_button.pressed.connect(func(): GameManager.go_to_main_menu())

	btn_up.pressed.connect(func(): _set_direction(Vector2i(0, -1)))
	btn_down.pressed.connect(func(): _set_direction(Vector2i(0, 1)))
	btn_left.pressed.connect(func(): _set_direction(Vector2i(-1, 0)))
	btn_right.pressed.connect(func(): _set_direction(Vector2i(1, 0)))

	start_game()

func _setup_customizer():
	if not customizer_modal:
		return
	var categories = [
		{
			"category_name": "SNAKES",
			"category_key": "snake_skin",
			"items": [
				{"id": "classic_green", "name": "Classic Green", "desc": "The timeless retro arcade serpent.", "req": "Starter"},
				{"id": "neon_viper", "name": "Neon Viper", "desc": "Glowing synthwave aesthetic.", "req": "Reach Score 10"},
				{"id": "desert_cobra", "name": "Desert Cobra", "desc": "Venomous golden scales.", "req": "Reach Score 35"},
				{"id": "cyber_dragon", "name": "Cyber Dragon", "desc": "Fiery crimson cyborg wyrm.", "req": "Reach Score 70"},
				{"id": "shadow_wyrm", "name": "Shadow Wyrm", "desc": "Mythic void cosmic dragon.", "req": "Reach Score 120"}
			]
		},
		{
			"category_name": "ARENAS",
			"category_key": "snake_arena",
			"items": [
				{"id": "classic_field", "name": "Classic Field", "desc": "Nostalgic green phosphor grid.", "req": "Starter"},
				{"id": "synthwave_grid", "name": "Synthwave Grid", "desc": "Cyberpunk neon battleground.", "req": "Reach Score 20"},
				{"id": "desert_dunes", "name": "Desert Dunes", "desc": "Warm sunlit desert arena.", "req": "Reach Score 50"},
				{"id": "frozen_tundra", "name": "Frozen Tundra", "desc": "Chilling glacial ice floor.", "req": "Reach Score 90"},
				{"id": "volcanic_abyss", "name": "Volcanic Abyss", "desc": "Infernal molten depths.", "req": "Reach Score 150"}
			]
		}
	]
	customizer_modal.setup("SNAKE UNLOCKS", categories)
	customizer_modal.item_equipped.connect(func(cat_key, item_id):
		if cat_key == "snake_skin":
			current_skin_id = item_id
		elif cat_key == "snake_arena":
			current_arena_id = item_id
		queue_redraw()
	)

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
		_check_unlock_milestones()
		_update_hud()
		_spawn_food()
	else:
		snake.pop_back()

	queue_redraw()

func _check_unlock_milestones():
	if score >= 10:
		SaveManager.unlock("snake_skin", "neon_viper", "Neon Viper")
	if score >= 20:
		SaveManager.unlock("snake_arena", "synthwave_grid", "Synthwave Grid")
	if score >= 35:
		SaveManager.unlock("snake_skin", "desert_cobra", "Desert Cobra")
	if score >= 50:
		SaveManager.unlock("snake_arena", "desert_dunes", "Desert Dunes")
	if score >= 70:
		SaveManager.unlock("snake_skin", "cyber_dragon", "Cyber Dragon")
	if score >= 90:
		SaveManager.unlock("snake_arena", "frozen_tundra", "Frozen Tundra")
	if score >= 120:
		SaveManager.unlock("snake_skin", "shadow_wyrm", "Shadow Wyrm")
	if score >= 150:
		SaveManager.unlock("snake_arena", "volcanic_abyss", "Volcanic Abyss")

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
	var arena = ARENA_DATA.get(current_arena_id, ARENA_DATA["classic_field"])
	var skin = SKIN_DATA.get(current_skin_id, SKIN_DATA["classic_green"])

	# 1. Background arena
	var arena_rect = Rect2(GRID_ORIGIN, Vector2(GRID_COLS * CELL_SIZE, GRID_ROWS * CELL_SIZE))
	draw_rect(arena_rect, arena["bg"])

	# Grid lines/dots for arena flavor
	for x in range(1, GRID_COLS):
		var px = GRID_ORIGIN.x + x * CELL_SIZE
		draw_line(Vector2(px, GRID_ORIGIN.y), Vector2(px, GRID_ORIGIN.y + GRID_ROWS * CELL_SIZE), arena["grid"], 1.0)
	for y in range(1, GRID_ROWS):
		var py = GRID_ORIGIN.y + y * CELL_SIZE
		draw_line(Vector2(GRID_ORIGIN.x, py), Vector2(GRID_ORIGIN.x + GRID_COLS * CELL_SIZE, py), arena["grid"], 1.0)

	# Arena border
	draw_rect(arena_rect, arena["border"], false, 2.0)

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
			# Head
			draw_rect(rect, skin["head"])
			var eye_color: Color = skin["eye"]
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
			# Body with alternating colors
			var body_col = skin["b1"] if i % 2 == 0 else skin["b2"]
			draw_rect(rect, body_col)
