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
@onready var customizer_modal: Control = $HUD/CustomizerModal

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
	hud.theme_toggle_pressed.connect(func(): customizer_modal.show_modal())

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

	_setup_customizer()
	var initial_road = SaveManager.get_equipped("racer_road", "city")
	road.set_road_by_id(initial_road)
	var initial_vehicle = SaveManager.get_equipped("racer_vehicle", "red_racer")
	player.apply_vehicle(initial_vehicle)

	start_game()

func _setup_customizer():
	if not customizer_modal:
		return
	var cdata = GameRegistry.get_customizer_data("retro_racer")
	customizer_modal.setup(cdata.get("title", "GARAGE & HIGHWAYS"), cdata.get("categories", []))
	customizer_modal.item_equipped.connect(func(cat_key, item_id):
		if cat_key == "racer_vehicle":
			player.apply_vehicle(item_id)
		elif cat_key == "racer_road":
			road.set_road_by_id(item_id)
	)

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

func _check_unlock_milestones():
	if distance_traveled >= 300:
		SaveManager.unlock("racer_vehicle", "superbike", "Superbike")
	if distance_traveled >= 400:
		SaveManager.unlock("racer_road", "cyber_neon", "Cyber Neon Road")
	if distance_traveled >= 700:
		SaveManager.unlock("racer_vehicle", "muscle_cruiser", "Muscle Cruiser")
	if distance_traveled >= 900:
		SaveManager.unlock("racer_road", "desert", "Desert Highway")
	if distance_traveled >= 1200:
		SaveManager.unlock("racer_vehicle", "turbo_bus", "Turbo Bus")
	if distance_traveled >= 1500:
		SaveManager.unlock("racer_road", "sunset_coast", "Sunset Coast")
	if distance_traveled >= 2000:
		SaveManager.unlock("racer_vehicle", "golden_f1", "Golden F1")
	if distance_traveled >= 2500:
		SaveManager.unlock("racer_road", "lava_gorge", "Lava Gorge")

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

	# Horizontal drag on the road directly steers the car. HUD buttons handle
	# their own events first, so boost and arrow controls keep working.
	if event is InputEventScreenDrag:
		player.set_drag_target_x(event.position.x)
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		player.set_drag_target_x(event.position.x)
		return
	if event is InputEventScreenTouch and event.pressed:
		player.set_drag_target_x(event.position.x)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		player.set_drag_target_x(event.position.x)
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
	_check_unlock_milestones()

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
