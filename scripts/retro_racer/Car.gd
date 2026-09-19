extends Area2D

signal crashed
signal near_miss_triggered(bonus_points: int)

const LANE_POSITIONS = [110.0, 180.0, 250.0]

var current_lane: int = 1
var target_x: float = 180.0
var move_speed: float = 14.0
var is_active: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	position = Vector2(LANE_POSITIONS[current_lane], 520.0)
	target_x = position.x
	area_entered.connect(_on_area_entered)

func _process(delta: float):
	if not is_active:
		return
	
	# Smoothly slide to lane position
	position.x = lerp(position.x, target_x, move_speed * delta)

func steer_left():
	if not is_active or current_lane <= 0:
		return
	current_lane -= 1
	target_x = LANE_POSITIONS[current_lane]

func steer_right():
	if not is_active or current_lane >= 2:
		return
	current_lane += 1
	target_x = LANE_POSITIONS[current_lane]

func _on_area_entered(other_area: Area2D):
	if not is_active:
		return
	if other_area.is_in_group("traffic"):
		is_active = false
		crashed.emit()

func reset():
	current_lane = 1
	target_x = LANE_POSITIONS[current_lane]
	position = Vector2(target_x, 520.0)
	is_active = true
	visible = true
