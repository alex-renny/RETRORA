extends Node2D

signal near_miss_occurred(bonus: int)

@export var traffic_scene: PackedScene = preload("res://scenes/retro_racer/TrafficCar.tscn")

const LANE_POSITIONS = [110.0, 180.0, 250.0]

var sedan_tex = preload("res://assets/retro_racer/traffic_sedan.png")
var compact_tex = preload("res://assets/retro_racer/traffic_compact.png")
var truck_tex = preload("res://assets/retro_racer/traffic_truck.png")

var spawn_timer: float = 0.0
var spawn_interval: float = 1.6
var is_spawning: bool = false
var player_ref: Node2D = null
var current_road_speed: float = 200.0

func setup(player: Node2D):
	player_ref = player

func start():
	is_spawning = true
	spawn_timer = 0.5

func stop():
	is_spawning = false

func clear_all():
	for child in get_children():
		child.queue_free()

func _process(delta: float):
	if not is_spawning:
		return
	
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		_spawn_traffic_wave()

func _spawn_traffic_wave():
	# Decide how many cars in this wave (1 or 2, never 3 so path is always open)
	var count = 1
	if randf() > 0.45:
		count = 2
	
	var lanes = [0, 1, 2]
	lanes.shuffle()

	for i in range(count):
		var lane_idx = lanes[i]
		_spawn_car(lane_idx)

func _spawn_car(lane: int):
	if not traffic_scene:
		return
	var car = traffic_scene.instantiate()
	add_child(car)
	car.position = Vector2(LANE_POSITIONS[lane], -50.0)

	var roll = randf()
	var tex = sedan_tex
	var speed_offset = 0.0

	if roll < 0.4:
		tex = sedan_tex
		speed_offset = current_road_speed * 0.45
	elif roll < 0.75:
		tex = compact_tex
		speed_offset = current_road_speed * 0.55
	else:
		tex = truck_tex
		speed_offset = current_road_speed * 0.35

	car.setup(tex, speed_offset, player_ref)
	car.near_miss.connect(_on_near_miss)

func _on_near_miss(bonus: int):
	near_miss_occurred.emit(bonus)

func update_speed(new_speed: float):
	current_road_speed = new_speed
	# Spawn slightly faster as speed increases, down to 0.9s
	spawn_interval = max(0.9, 1.8 - (new_speed - 200.0) / 400.0)
