extends Node2D

const BASE_SPEED: float = 200.0
const MAX_SPEED: float = 460.0
const SPEED_RAMP_RATE: float = 6.0 # kmh increase per 100m
const BOOST_MULTIPLIER: float = 1.5

enum State { READY, RACING, GAMEOVER, PAUSED }
var current_state: State = State.READY

var distance_traveled: float = 0.0
var high_score: int = 0
var current_speed: float = BASE_SPEED
var boost_energy: float = 100.0
var is_boosting: bool = false
var current_theme: int = 0

# Screen Shake
var shake_intensity: float = 0.0

@onready var road: Node2D = $RoadScroller
@onready var player: Area2D = $PlayerCar
@onready var spawner: Node2D = $TrafficSpawner
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Camera2D

func _ready():
	high_score = SaveManager.get_high_score("retro_racer")
	
	spawner.setup(player)
	player.crashed.connect(_on_player_crashed)
	spawner.near_miss_occurred.connect(_on_near_miss)

	# Connect HUD signals
	hud.steer_left_pressed.connect(_on_steer_left)
	hud.steer_right_pressed.connect(_on_steer_right)
	hud.boost_pressed.connect(_on_boost_pressed)
	hud.pause_pressed.connect(_toggle_pause)
	hud.retry_pressed.connect(restart_game)
	hud.menu_pressed.connect(_go_to_menu)
	hud.theme_toggle_pressed.connect(_cycle_theme)

	start_game()

func start_game():
	distance_traveled = 0.0
	current_speed = BASE_SPEED
	boost_energy = 100.0
	is_boosting = false
	current_state = State.RACING

	player.reset()
	spawner.clear_all()
	spawner.start()
	hud.hide_game_over()

func restart_game():
	start_game()

func _go_to_menu():
	GameManager.go_to_main_menu()

func _cycle_theme():
	current_theme = (current_theme + 1) % 3
	road.set_theme(current_theme)

func _on_steer_left():
	if current_state == State.RACING:
		player.steer_left()

func _on_steer_right():
	if current_state == State.RACING:
		player.steer_right()

func _on_boost_pressed(active: bool):
	if current_state == State.RACING:
		is_boosting = active and boost_energy > 5.0

func _unhandled_input(event: InputEvent):
	if current_state != State.RACING:
		return

	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		player.steer_left()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		player.steer_right()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_accept"):
		is_boosting = true
	elif event.is_action_released("ui_up") or event.is_action_released("ui_accept"):
		is_boosting = false
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_A or event.keycode == KEY_LEFT:
			player.steer_left()
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			player.steer_right()
		elif event.keycode == KEY_W or event.keycode == KEY_SPACE:
			is_boosting = true
		elif event.keycode == KEY_ESCAPE:
			_toggle_pause()
	elif event is InputEventKey and not event.pressed:
		if event.keycode == KEY_W or event.keycode == KEY_SPACE:
			is_boosting = false

func _process(delta: float):
	if current_state != State.RACING:
		_process_camera_shake(delta)
		return

	# Handle Boost Energy & Recharge
	if is_boosting and boost_energy > 0.0:
		boost_energy = max(0.0, boost_energy - (100.0 / 3.5) * delta)
		if boost_energy <= 0.0:
			is_boosting = false
	elif not is_boosting and boost_energy < 100.0:
		boost_energy = min(100.0, boost_energy + (100.0 / 5.0) * delta)

	# Calculate Speed & Distance
	var target_speed = min(MAX_SPEED, BASE_SPEED + (distance_traveled / 100.0) * SPEED_RAMP_RATE)
	if is_boosting:
		target_speed *= BOOST_MULTIPLIER

	current_speed = lerp(current_speed, target_speed, 4.0 * delta)
	distance_traveled += (current_speed * 0.1) * delta

	# Update Road & Spawner
	road.set_speed(current_speed)
	spawner.update_speed(current_speed)

	# Update HUD
	var speed_kmh = int(current_speed * 0.5)
	hud.update_hud(int(distance_traveled), high_score, boost_energy / 100.0, speed_kmh)

	_process_camera_shake(delta)

func _process_camera_shake(delta: float):
	if shake_intensity > 0.0:
		shake_intensity = max(0.0, shake_intensity - 12.0 * delta)
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		camera.offset = Vector2.ZERO

func _on_near_miss(bonus: int):
	if current_state != State.RACING:
		return
	distance_traveled += bonus
	hud.show_near_miss()
	shake_intensity = 3.0

func _on_player_crashed():
	current_state = State.GAMEOVER
	spawner.stop()
	road.set_speed(0.0)
	shake_intensity = 15.0

	var final_dist = int(distance_traveled)
	var is_new_record = false
	if final_dist > high_score:
		high_score = final_dist
		SaveManager.set_high_score("retro_racer", high_score)
		is_new_record = true

	hud.show_game_over(final_dist, high_score, is_new_record)

func _toggle_pause():
	if current_state == State.GAMEOVER:
		return
	var overlay = GameManager.open_pause_overlay($HUD)
	if overlay:
		current_state = State.PAUSED
		spawner.stop()
		overlay.tree_exiting.connect(func():
			if current_state == State.PAUSED:
				current_state = State.RACING
				spawner.start()
		)
