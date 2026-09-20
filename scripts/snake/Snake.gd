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

var anim_time: float = 0.0
var tongue_timer: float = 0.0

const SKIN_DATA = {
	"classic_green": {
		"head": Color(0.18, 0.82, 0.35),
		"b1": Color(0.14, 0.72, 0.28),
		"b2": Color(0.10, 0.60, 0.22),
		"stripe": Color(0.35, 0.95, 0.50),
		"eye": Color(0.05, 0.15, 0.05)
	},
	"neon_viper": {
		"head": Color(0.0, 0.95, 0.85),
		"b1": Color(0.0, 0.75, 0.95),
		"b2": Color(0.75, 0.15, 0.95),
		"stripe": Color(0.60, 1.0, 1.0),
		"eye": Color(0.05, 0.05, 0.2)
	},
	"desert_cobra": {
		"head": Color(0.95, 0.70, 0.18),
		"b1": Color(0.85, 0.55, 0.12),
		"b2": Color(0.70, 0.40, 0.08),
		"stripe": Color(1.0, 0.88, 0.45),
		"eye": Color(0.5, 0.1, 0.05)
	},
	"cyber_dragon": {
		"head": Color(1.0, 0.25, 0.35),
		"b1": Color(0.90, 0.15, 0.20),
		"b2": Color(0.98, 0.65, 0.10),
		"stripe": Color(1.0, 0.85, 0.40),
		"eye": Color(0.1, 0.8, 0.9)
	},
	"shadow_wyrm": {
		"head": Color(0.65, 0.35, 0.95),
		"b1": Color(0.40, 0.18, 0.65),
		"b2": Color(0.25, 0.10, 0.45),
		"stripe": Color(0.85, 0.55, 1.0),
		"eye": Color(0.95, 0.3, 0.95)
	}
}

const ARENA_DATA_DARK = {
	"classic_field": {
		"bg": Color(0.08, 0.13, 0.09),
		"border": Color(0.3, 0.65, 0.35),
		"grid": Color(0.11, 0.18, 0.12)
	},
	"synthwave_grid": {
		"bg": Color(0.08, 0.04, 0.14),
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

const ARENA_DATA_LIGHT = {
	"classic_field": {
		"bg": Color(0.92, 0.98, 0.94),
		"border": Color(0.15, 0.70, 0.30),
		"grid": Color(0.82, 0.93, 0.85)
	},
	"synthwave_grid": {
		"bg": Color(0.98, 0.94, 0.98),
		"border": Color(0.85, 0.20, 0.75),
		"grid": Color(0.93, 0.85, 0.95)
	},
	"desert_dunes": {
		"bg": Color(0.99, 0.96, 0.88),
		"border": Color(0.85, 0.60, 0.15),
		"grid": Color(0.94, 0.88, 0.76)
	},
	"frozen_tundra": {
		"bg": Color(0.93, 0.97, 1.0),
		"border": Color(0.20, 0.65, 0.95),
		"grid": Color(0.83, 0.91, 0.98)
	},
	"volcanic_abyss": {
		"bg": Color(0.99, 0.92, 0.92),
		"border": Color(0.90, 0.25, 0.20),
		"grid": Color(0.95, 0.84, 0.84)
	}
}

func _ready():
	high_score = SaveManager.get_high_score("snake")
	best_label.text = "BEST: %d" % high_score

	current_skin_id = SaveManager.get_equipped("snake_skin", "classic_green")
	current_arena_id = SaveManager.get_equipped("snake_arena", "classic_field")

	SettingsManager.theme_changed.connect(func(_thm): _apply_theme())
	_apply_theme()

	_setup_customizer()

	if skin_button:
		skin_button.pressed.connect(func(): customizer_modal.show_modal())
	pause_button.pressed.connect(_toggle_pause)
	retry_button.pressed.connect(start_game)
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

	btn_up.pressed.connect(func(): _set_direction(Vector2i(0, -1)))
	btn_down.pressed.connect(func(): _set_direction(Vector2i(0, 1)))
	btn_left.pressed.connect(func(): _set_direction(Vector2i(-1, 0)))
	btn_right.pressed.connect(func(): _set_direction(Vector2i(1, 0)))

	start_game()

func _apply_theme():
	var p = SettingsManager.get_palette()
	score_label.add_theme_color_override("font_color", p["text_primary"])
	best_label.add_theme_color_override("font_color", p["text_secondary"])
	var top_bar = get_node_or_null("HUD/TopBar")
	if top_bar is Panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = p["card_bg"]
		sb.set_border_width_all(1)
		sb.border_color = p["card_border"]
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		top_bar.add_theme_stylebox_override("panel", sb)
	queue_redraw()

func _setup_customizer():
	if not customizer_modal:
		return
	var cdata = GameRegistry.get_customizer_data("snake")
	customizer_modal.setup(cdata.get("title", "SNAKE UNLOCKS"), cdata.get("categories", []))
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

	anim_time += delta
	tongue_timer += delta
	if tongue_timer > 2.4:
		tongue_timer = 0.0

	timer += delta
	if timer >= tick_interval:
		timer = 0.0
		_move_snake()

	queue_redraw()

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
	var is_light = SettingsManager.is_light_theme()
	var arena_dict = ARENA_DATA_LIGHT if is_light else ARENA_DATA_DARK
	var arena = arena_dict.get(current_arena_id, arena_dict["classic_field"])
	var skin = SKIN_DATA.get(current_skin_id, SKIN_DATA["classic_green"])

	# 1. Background arena
	var arena_rect = Rect2(GRID_ORIGIN, Vector2(GRID_COLS * CELL_SIZE, GRID_ROWS * CELL_SIZE))
	draw_rect(arena_rect, arena["bg"])

	# Subtle grid lines
	for x in range(1, GRID_COLS):
		var px = GRID_ORIGIN.x + x * CELL_SIZE
		draw_line(Vector2(px, GRID_ORIGIN.y), Vector2(px, GRID_ORIGIN.y + GRID_ROWS * CELL_SIZE), arena["grid"], 1.0)
	for y in range(1, GRID_ROWS):
		var py = GRID_ORIGIN.y + y * CELL_SIZE
		draw_line(Vector2(GRID_ORIGIN.x, py), Vector2(GRID_ORIGIN.x + GRID_COLS * CELL_SIZE, py), arena["grid"], 1.0)

	# Arena border
	draw_rect(arena_rect, arena["border"], false, 2.5)

	# 2. 3D Juicy Apple with sparkle particles & pulse
	var food_center = GRID_ORIGIN + Vector2(food_pos) * CELL_SIZE + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
	var apple_pulse = 1.0 + sin(anim_time * 6.0) * 0.05
	var r_apple = (CELL_SIZE * 0.42) * apple_pulse

	# Apple drop shadow
	draw_circle(food_center + Vector2(1.0, 2.0), r_apple * 0.9, Color(0, 0, 0, 0.22 if is_light else 0.45))
	# Apple base body
	draw_circle(food_center, r_apple, Color(0.92, 0.16, 0.16))
	# Apple bottom shaded sphere rim
	draw_circle(food_center + Vector2(0.8, 1.2), r_apple * 0.82, Color(0.80, 0.10, 0.12))
	# Apple top-left radial specular shine
	draw_circle(food_center + Vector2(-r_apple * 0.32, -r_apple * 0.32), r_apple * 0.38, Color(1.0, 0.48, 0.48, 0.85))
	# Catchlight bright white dot
	draw_circle(food_center + Vector2(-r_apple * 0.35, -r_apple * 0.35), 1.5, Color.WHITE)

	# Curved brown stem
	var stem_color = Color(0.48, 0.28, 0.12)
	draw_line(food_center + Vector2(0, -r_apple * 0.6), food_center + Vector2(2.0, -r_apple - 3.5), stem_color, 1.6)

	# Vibrant green leaf
	var leaf_pts = PackedVector2Array([
		food_center + Vector2(1.0, -r_apple * 0.8),
		food_center + Vector2(6.0, -r_apple - 2.5),
		food_center + Vector2(7.5, -r_apple * 0.6),
		food_center + Vector2(2.5, -r_apple * 0.5)
	])
	draw_colored_polygon(leaf_pts, Color(0.22, 0.85, 0.28))

	# Orbiting sparkle particles around apple
	for s_idx in range(3):
		var spark_ang = anim_time * 3.2 + float(s_idx) * (TAU / 3.0)
		var spark_rad = r_apple + 4.5 + sin(anim_time * 5.0 + s_idx) * 2.0
		var sp_pos = food_center + Vector2(cos(spark_ang), sin(spark_ang)) * spark_rad
		var sp_alpha = 0.4 + 0.6 * sin(anim_time * 6.0 + s_idx * 2.0)
		draw_circle(sp_pos, 1.2, Color(1.0, 0.92, 0.4, clamp(sp_alpha, 0.0, 1.0)))

	# 3. Organic Snake Body & Slither Undulation
	var dir_norm = Vector2(-direction.y, direction.x)

	# Draw body from tail to neck (so head renders on top)
	for i in range(snake.size() - 1, 0, -1):
		var part = snake[i]
		var base_center = GRID_ORIGIN + Vector2(part) * CELL_SIZE + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		var wave_offset = dir_norm * sin(anim_time * 12.0 - float(i) * 0.55) * (1.6 * clamp(float(i) / 4.0, 0.0, 1.0))
		var center = base_center + wave_offset

		# Taper tail radius
		var seg_ratio = 1.0
		if i == snake.size() - 1:
			seg_ratio = 0.65
		elif i == snake.size() - 2:
			seg_ratio = 0.82
		var seg_radius = (CELL_SIZE * 0.46) * seg_ratio

		# Drop shadow under segment
		draw_circle(center + Vector2(1.0, 1.5), seg_radius, Color(0, 0, 0, 0.18 if is_light else 0.4))

		# Alternating scale colors
		var body_col = skin["b1"] if i % 2 == 0 else skin["b2"]
		draw_circle(center, seg_radius, body_col)

		# Dorsal highlight ridge on back
		draw_circle(center - Vector2(dir_norm.x, dir_norm.y) * 1.5, seg_radius * 0.42, skin.get("stripe", skin["head"]))

	# 4. Expressive Snake Head
	if snake.size() > 0:
		var head_part = snake[0]
		var head_center = GRID_ORIGIN + Vector2(head_part) * CELL_SIZE + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		var head_radius = CELL_SIZE * 0.48

		# Head drop shadow
		draw_circle(head_center + Vector2(1.0, 1.5), head_radius, Color(0, 0, 0, 0.22 if is_light else 0.45))

		# Head base shape
		draw_circle(head_center, head_radius, skin["head"])

		# Head snout extension in travel direction
		var dir_v = Vector2(direction)
		draw_circle(head_center + dir_v * 3.5, head_radius * 0.75, skin["head"])

		# Forked flickering tongue
		if tongue_timer < 0.35 and current_state == State.PLAYING:
			var tongue_root = head_center + dir_v * (head_radius + 1.0)
			var tongue_flick = sin(anim_time * 40.0) * 1.5
			var tongue_ext = dir_v * 7.5 + dir_norm * tongue_flick
			var tongue_tip = tongue_root + tongue_ext
			var fork_l = tongue_tip + dir_v * 3.0 + dir_norm * 2.5
			var fork_r = tongue_tip + dir_v * 3.0 - dir_norm * 2.5

			draw_line(tongue_root, tongue_tip, Color(0.95, 0.15, 0.2), 1.8)
			draw_line(tongue_tip, fork_l, Color(0.95, 0.15, 0.2), 1.4)
			draw_line(tongue_tip, fork_r, Color(0.95, 0.15, 0.2), 1.4)

		# Eyes with shiny catchlights
		var eye_offset_fwd = dir_v * 2.5
		var eye_offset_lat = dir_norm * 4.2
		var eye_l = head_center + eye_offset_fwd + eye_offset_lat
		var eye_r = head_center + eye_offset_fwd - eye_offset_lat

		# Eye whites
		draw_circle(eye_l, 2.8, Color(0.98, 0.98, 0.98))
		draw_circle(eye_r, 2.8, Color(0.98, 0.98, 0.98))

		# Pupil looking forward
		var pupil_pos_l = eye_l + dir_v * 0.8
		var pupil_pos_r = eye_r + dir_v * 0.8
		draw_circle(pupil_pos_l, 1.6, skin["eye"])
		draw_circle(pupil_pos_r, 1.6, skin["eye"])

		# Specular glint (catchlight)
		draw_circle(pupil_pos_l - Vector2(0.5, 0.5), 0.7, Color.WHITE)
		draw_circle(pupil_pos_r - Vector2(0.5, 0.5), 0.7, Color.WHITE)
