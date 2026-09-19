extends Node2D

# HamsterGameController manages the 3x3 watch Whack-a-Hamster arcade game.

const GAME_DURATION: float = 60.0

enum State { PLAYING, PAUSED, GAME_OVER }
var current_state: State = State.PLAYING

var time_left: float = GAME_DURATION
var score: int = 0
var high_score: int = 0
var whacks_count: int = 0
var combo: int = 0
var max_combo: int = 0

# Spawning system
var spawn_timer: float = 0.0
var holes: Array = []

# Camera Shake
var shake_intensity: float = 0.0

@onready var camera: Camera2D = $Camera2D
@onready var audio: Node = $HamsterAudio
@onready var hud: CanvasLayer = $HUD

# HUD Nodes
@onready var timer_label: Label = $HUD/TopBar/TimerContainer/TimerLabel
@onready var clock_icon: Control = $HUD/TopBar/TimerContainer/ClockIcon
@onready var score_label: Label = $HUD/TopBar/ScoreLabel
@onready var combo_label: Label = $HUD/TopBar/ComboLabel
@onready var pause_button: Button = $HUD/TopBar/PauseButton

# Bottom Bar Nodes
@onready var back_button: Button = $HUD/BottomBar/HBox/BackButton
@onready var count_label: Label = $HUD/BottomBar/HBox/CountBadge/CountLabel
@onready var restart_button: Button = $HUD/BottomBar/HBox/RestartButton

# Game Over Dialog Nodes
@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var final_score_label: Label = $HUD/GameOverPanel/VBox/FinalScoreLabel
@onready var final_whacks_label: Label = $HUD/GameOverPanel/VBox/FinalWhacksLabel
@onready var final_best_label: Label = $HUD/GameOverPanel/VBox/FinalBestLabel
@onready var new_record_label: Label = $HUD/GameOverPanel/VBox/NewRecordLabel
@onready var stars_label: Label = $HUD/GameOverPanel/VBox/StarsLabel
@onready var retry_button: Button = $HUD/GameOverPanel/VBox/BtnContainer/RetryButton
@onready var menu_button: Button = $HUD/GameOverPanel/VBox/BtnContainer/MenuButton

func _ready():
	high_score = SaveManager.get_high_score("hamster_game")
	_setup_holes()
	_bind_ui()
	_reset_game()

func _setup_holes():
	holes.clear()
	var holes_container = $HolesContainer
	for i in range(9):
		var hole = holes_container.get_node_or_null("Hole%d" % i)
		if hole:
			hole.hole_index = i
			hole.hole_whacked.connect(_on_hole_whacked)
			holes.append(hole)

func _bind_ui():
	pause_button.pressed.connect(_toggle_pause)
	back_button.pressed.connect(func(): GameManager.go_to_game_select())
	restart_button.pressed.connect(_reset_game)
	retry_button.pressed.connect(_reset_game)
	menu_button.pressed.connect(func(): GameManager.go_to_game_select())

func _reset_game():
	time_left = GAME_DURATION
	score = 0
	whacks_count = 0
	combo = 0
	max_combo = 0
	spawn_timer = 0.5
	shake_intensity = 0.0
	current_state = State.PLAYING
	game_over_panel.visible = false

	for h in holes:
		h.current_state = h.State.EMPTY
		h.queue_redraw()

	_update_hud()

func _process(delta: float):
	if current_state != State.PLAYING:
		return

	# Timer countdown
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_game_over()
		return

	# Clock icon pulse under 10s
	if time_left <= 10.0:
		timer_label.modulate = Color(1.0, 0.3, 0.3) if fmod(time_left, 0.5) < 0.25 else Color.WHITE
		if fmod(time_left, 1.0) < delta:
			audio.play_tick()
	else:
		timer_label.modulate = Color.WHITE

	# Spawner update
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_hamsters()
		# Dynamic interval ramping (1.1s down to 0.45s)
		var progress = 1.0 - (time_left / GAME_DURATION)
		var interval = lerp(1.15, 0.45, progress)
		spawn_timer = randf_range(interval * 0.85, interval * 1.15)

	# Screen Shake
	if shake_intensity > 0.0:
		shake_intensity = max(0.0, shake_intensity - 20.0 * delta)
		if SettingsManager.screen_shake_enabled:
			camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		camera.offset = Vector2.ZERO

	_update_hud()

func _spawn_hamsters():
	var empty_holes = []
	for h in holes:
		if h.current_state == h.State.EMPTY:
			empty_holes.append(h)

	if empty_holes.is_empty():
		return

	# Determine how many to spawn
	var to_spawn = 1
	if time_left < 20.0 and empty_holes.size() >= 3 and randf() < 0.55:
		to_spawn = 3
	elif time_left < 40.0 and empty_holes.size() >= 2 and randf() < 0.65:
		to_spawn = 2

	empty_holes.shuffle()
	var progress = 1.0 - (time_left / GAME_DURATION)
	var peek_time = lerp(1.25, 0.65, progress)

	for i in range(min(to_spawn, empty_holes.size())):
		var h = empty_holes[i]
		var roll = randf()
		var type = h.HamsterType.NORMAL
		if roll < 0.15:
			type = h.HamsterType.GOLDEN
		elif roll < 0.25:
			type = h.HamsterType.BOMB

		h.spawn(type, peek_time)
		audio.play_pop()

func _on_hole_whacked(hole_idx: int, type: int):
	var h = holes[hole_idx]
	whacks_count += 1

	if type == h.HamsterType.NORMAL:
		combo += 1
		max_combo = max(max_combo, combo)
		var mult = min(combo, 5)
		var pts = 100 * mult
		score += pts
		audio.play_whack()
		audio.play_dizzy()
		shake_intensity = 2.5

		var txt = "+%d" % pts
		if mult > 1:
			txt += " (x%d!)" % mult
		h.show_floating_score(txt, Color(1.0, 0.9, 0.2))

	elif type == h.HamsterType.GOLDEN:
		combo += 1
		max_combo = max(max_combo, combo)
		var pts = 250 * min(combo, 5)
		score += pts
		time_left = min(GAME_DURATION, time_left + 3.0)
		audio.play_whack()
		audio.play_bonus()
		shake_intensity = 4.0
		h.show_floating_score("+%d! (+3s)" % pts, Color(1.0, 0.84, 0.0))

	elif type == h.HamsterType.BOMB:
		combo = 0 # Break combo
		var penalty = 150
		score = max(0, score - penalty)
		time_left = max(0.0, time_left - 3.0)
		audio.play_penalty()
		shake_intensity = 6.0
		h.show_floating_score("-%d (-3s!)" % penalty, Color(1.0, 0.3, 0.3))

	_update_hud()

func _update_hud():
	timer_label.text = "%02d" % int(ceil(time_left))
	score_label.text = "SCORE: %05d" % score
	count_label.text = "%d" % whacks_count

	if combo > 1:
		combo_label.text = "COMBO x%d!" % min(combo, 5)
		combo_label.visible = true
	else:
		combo_label.visible = false

func _game_over():
	current_state = State.GAME_OVER
	audio.play_game_over()

	var is_new_record = false
	if score > high_score:
		high_score = score
		SaveManager.set_high_score("hamster_game", high_score)
		is_new_record = true

	final_score_label.text = "FINAL SCORE: %d" % score
	final_whacks_label.text = "HAMSTERS WHACKED: %d (MAX COMBO: %d)" % [whacks_count, max_combo]
	final_best_label.text = "BEST RECORD: %d pts" % high_score
	new_record_label.visible = is_new_record

	# Star rating
	var stars = "★☆☆"
	if score >= 3000:
		stars = "★★★ PERFECT!"
	elif score >= 1500:
		stars = "★★☆ GREAT JOB!"
	elif score >= 500:
		stars = "★☆☆ NICE TRY!"
	else:
		stars = "☆☆☆ TRY AGAIN!"
	stars_label.text = stars

	game_over_panel.visible = true

func _toggle_pause():
	if current_state == State.GAME_OVER:
		return
	var overlay = GameManager.open_pause_overlay($HUD)
	if overlay:
		current_state = State.PAUSED
		overlay.tree_exiting.connect(func():
			if current_state == State.PAUSED:
				current_state = State.PLAYING
		)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause()
			return

		if current_state != State.PLAYING:
			return

		# Numpad & Keyboard Grid mapping (3x3):
		# [7/Q/1] [8/W/2] [9/E/3]
		# [4/A/4] [5/S/5] [6/D/6]
		# [1/Z/7] [2/X/8] [3/C/9]
		var idx = -1
		match event.keycode:
			KEY_KP_7, KEY_Q, KEY_1: idx = 0
			KEY_KP_8, KEY_W, KEY_2: idx = 1
			KEY_KP_9, KEY_E, KEY_3: idx = 2
			KEY_KP_4, KEY_A, KEY_4: idx = 3
			KEY_KP_5, KEY_S, KEY_5: idx = 4
			KEY_KP_6, KEY_D, KEY_6: idx = 5
			KEY_KP_1, KEY_Z, KEY_7: idx = 6
			KEY_KP_2, KEY_X, KEY_8: idx = 7
			KEY_KP_3, KEY_C, KEY_9: idx = 8

		if idx >= 0 and idx < holes.size():
			holes[idx].try_whack()

func _draw():
	# 1. Sky Top
	draw_rect(Rect2(0, 0, 360, 95), Color(0.32, 0.76, 0.98))

	# Clouds
	_draw_cloud(Vector2(55, 38), 24)
	_draw_cloud(Vector2(290, 42), 22)

	# 2. Horizon Bushes
	_draw_horizon_bushes()

	# 3. Main Grassy Playfield
	draw_rect(Rect2(0, 95, 360, 545), Color(0.38, 0.86, 0.32))

	# Decorative blades of grass
	_draw_grass_details()

func _draw_cloud(pos: Vector2, size: float):
	var col = Color(1.0, 1.0, 1.0, 0.9)
	draw_circle(pos, size * 0.7, col)
	draw_circle(pos + Vector2(size * 0.6, size * 0.1), size * 0.55, col)
	draw_circle(pos - Vector2(size * 0.6, -size * 0.1), size * 0.55, col)

func _draw_horizon_bushes():
	var bush_col = Color(0.24, 0.78, 0.38)
	var bush_hl = Color(0.36, 0.88, 0.48)
	for i in range(12):
		var x = float(i) * 32.0 + 8.0
		draw_circle(Vector2(x, 96), 18.0, bush_col)
		draw_circle(Vector2(x - 3, 91), 10.0, bush_hl)

func _draw_grass_details():
	var dark_grass = Color(0.30, 0.75, 0.25, 0.6)
	var tufts = [
		Vector2(20, 210), Vector2(330, 220), Vector2(175, 225),
		Vector2(45, 350), Vector2(310, 360), Vector2(170, 365),
		Vector2(25, 500), Vector2(335, 490), Vector2(185, 505)
	]
	for t in tufts:
		draw_line(t, t + Vector2(-3, -7), dark_grass, 1.5)
		draw_line(t, t + Vector2(0, -9), dark_grass, 1.5)
		draw_line(t, t + Vector2(4, -6), dark_grass, 1.5)
