extends Area2D

signal crashed
signal near_miss_triggered(bonus_points: int)

const LANE_POSITIONS = [110.0, 180.0, 250.0]

var current_lane: int = 1
var target_x: float = 180.0
var move_speed: float = 14.0
var is_active: bool = true
var current_vehicle_id: String = "red_racer"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	position = Vector2(LANE_POSITIONS[current_lane], 520.0)
	target_x = position.x
	area_entered.connect(_on_area_entered)
	apply_vehicle(SaveManager.get_equipped("racer_vehicle", "red_racer"))

func apply_vehicle(vehicle_id: String):
	current_vehicle_id = vehicle_id
	if sprite:
		sprite.visible = false
	match vehicle_id:
		"superbike":
			move_speed = 18.0
			if collision_shape and collision_shape.shape is RectangleShape2D:
				collision_shape.shape.size = Vector2(12, 32)
		"muscle_cruiser":
			move_speed = 13.0
			if collision_shape and collision_shape.shape is RectangleShape2D:
				collision_shape.shape.size = Vector2(20, 42)
		"turbo_bus":
			move_speed = 10.5
			if collision_shape and collision_shape.shape is RectangleShape2D:
				collision_shape.shape.size = Vector2(24, 52)
		"golden_f1":
			move_speed = 16.0
			if collision_shape and collision_shape.shape is RectangleShape2D:
				collision_shape.shape.size = Vector2(20, 42)
		_: # red_racer
			move_speed = 14.0
			if collision_shape and collision_shape.shape is RectangleShape2D:
				collision_shape.shape.size = Vector2(18, 38)
	queue_redraw()

func _process(delta: float):
	if not is_active:
		return
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

func _draw():
	match current_vehicle_id:
		"superbike":
			_draw_superbike()
		"muscle_cruiser":
			_draw_muscle_cruiser()
		"turbo_bus":
			_draw_turbo_bus()
		"golden_f1":
			_draw_golden_f1()
		_:
			_draw_red_racer()

func _draw_red_racer():
	# Wheels
	var wheel_col = Color(0.15, 0.15, 0.15)
	draw_rect(Rect2(-11, -16, 4, 8), wheel_col)
	draw_rect(Rect2(7, -16, 4, 8), wheel_col)
	draw_rect(Rect2(-11, 8, 4, 8), wheel_col)
	draw_rect(Rect2(7, 8, 4, 8), wheel_col)

	# Body
	draw_rect(Rect2(-8, -18, 16, 36), Color(0.85, 0.15, 0.15))
	draw_rect(Rect2(-2, -18, 4, 36), Color(1.0, 1.0, 1.0)) # Racing stripe

	# Windshield & Roof
	draw_rect(Rect2(-6, -6, 12, 10), Color(0.1, 0.15, 0.25))
	draw_rect(Rect2(-5, -2, 10, 6), Color(0.7, 0.1, 0.1))

	# Headlights & Taillights
	draw_rect(Rect2(-7, -19, 3, 2), Color(1.0, 0.95, 0.4))
	draw_rect(Rect2(4, -19, 3, 2), Color(1.0, 0.95, 0.4))
	draw_rect(Rect2(-7, 17, 3, 2), Color(1.0, 0.1, 0.1))
	draw_rect(Rect2(4, 17, 3, 2), Color(1.0, 0.1, 0.1))

func _draw_superbike():
	# Front and Rear tires
	draw_rect(Rect2(-3, -16, 6, 9), Color(0.12, 0.12, 0.12))
	draw_rect(Rect2(-3, 8, 6, 9), Color(0.12, 0.12, 0.12))

	# Frame
	draw_rect(Rect2(-4, -10, 8, 20), Color(0.0, 0.9, 0.6))
	# Handlebars
	draw_line(Vector2(-7, -10), Vector2(7, -10), Color(0.8, 0.8, 0.8), 2.0)
	# Rider
	draw_circle(Vector2(0, -1), 4.0, Color(1.0, 0.85, 0.2)) # Helmet
	draw_rect(Rect2(-3, 3, 6, 5), Color(0.15, 0.15, 0.2)) # Jacket

	# Headlight & Taillight
	draw_rect(Rect2(-2, -17, 4, 2), Color(1.0, 1.0, 0.5))
	draw_rect(Rect2(-2, 16, 4, 2), Color(1.0, 0.2, 0.1))

func _draw_muscle_cruiser():
	# Wide wheels
	var wheel_col = Color(0.12, 0.12, 0.12)
	draw_rect(Rect2(-12, -16, 4, 9), wheel_col)
	draw_rect(Rect2(8, -16, 4, 9), wheel_col)
	draw_rect(Rect2(-12, 8, 4, 9), wheel_col)
	draw_rect(Rect2(8, 8, 4, 9), wheel_col)

	# Deep Plum Body
	draw_rect(Rect2(-9, -20, 18, 40), Color(0.25, 0.1, 0.45))
	# Dual silver stripes
	draw_line(Vector2(-3, -20), Vector2(-3, 20), Color(0.85, 0.85, 0.9), 1.5)
	draw_line(Vector2(3, -20), Vector2(3, 20), Color(0.85, 0.85, 0.9), 1.5)

	# Big Chrome Blower on Hood
	draw_rect(Rect2(-3, -15, 6, 5), Color(0.85, 0.9, 0.95))
	# Dark Tinted Glass
	draw_rect(Rect2(-7, -7, 14, 12), Color(0.08, 0.08, 0.15))
	# Rear Spoiler
	draw_rect(Rect2(-10, 18, 20, 3), Color(0.18, 0.05, 0.35))
	# Lights
	draw_rect(Rect2(-8, -21, 4, 2), Color(1.0, 0.9, 0.3))
	draw_rect(Rect2(4, -21, 4, 2), Color(1.0, 0.9, 0.3))
	draw_rect(Rect2(-8, 19, 4, 2), Color(1.0, 0.1, 0.2))
	draw_rect(Rect2(4, 19, 4, 2), Color(1.0, 0.1, 0.2))

func _draw_turbo_bus():
	# Wheels tucked slightly
	var wheel_col = Color(0.1, 0.1, 0.1)
	draw_rect(Rect2(-13, -20, 3, 10), wheel_col)
	draw_rect(Rect2(10, -20, 3, 10), wheel_col)
	draw_rect(Rect2(-13, 12, 3, 10), wheel_col)
	draw_rect(Rect2(10, 12, 3, 10), wheel_col)

	# Bus Body (Arcade Yellow/Orange)
	draw_rect(Rect2(-11, -26, 22, 52), Color(0.95, 0.65, 0.08))
	draw_rect(Rect2(-11, -26, 22, 5), Color(0.8, 0.5, 0.05)) # Front bumper

	# Front Windshield
	draw_rect(Rect2(-9, -23, 18, 7), Color(0.2, 0.7, 0.9))

	# Side Windows
	for wy in [-12, -3, 6, 15]:
		draw_rect(Rect2(-10, wy, 4, 6), Color(0.2, 0.7, 0.9))
		draw_rect(Rect2(6, wy, 4, 6), Color(0.2, 0.7, 0.9))

	# Roof AC Units
	draw_rect(Rect2(-4, -6, 8, 14), Color(0.75, 0.5, 0.05))

	# Lights
	draw_rect(Rect2(-10, -27, 4, 2), Color(1.0, 1.0, 0.6))
	draw_rect(Rect2(6, -27, 4, 2), Color(1.0, 1.0, 0.6))
	draw_rect(Rect2(-10, 25, 4, 2), Color(1.0, 0.1, 0.1))
	draw_rect(Rect2(6, 25, 4, 2), Color(1.0, 0.1, 0.1))

func _draw_golden_f1():
	# Wide exposed F1 slicks
	var tire_col = Color(0.1, 0.1, 0.1)
	draw_rect(Rect2(-14, -16, 5, 9), tire_col)
	draw_rect(Rect2(9, -16, 5, 9), tire_col)
	draw_rect(Rect2(-15, 9, 6, 11), tire_col)
	draw_rect(Rect2(9, 9, 6, 11), tire_col)

	# Front Aerodynamic Wing
	draw_rect(Rect2(-13, -21, 26, 4), Color(0.9, 0.75, 0.1))

	# Needle Nose & Fuselage
	draw_polygon(PackedVector2Array([
		Vector2(0, -21),
		Vector2(-4, -10),
		Vector2(-7, 2),
		Vector2(-7, 18),
		Vector2(7, 18),
		Vector2(7, 2),
		Vector2(4, -10)
	]), PackedColorArray([Color(1.0, 0.84, 0.0)]))

	# Open Cockpit & Driver Helmet
	draw_rect(Rect2(-4, -4, 8, 8), Color(0.08, 0.08, 0.08))
	draw_circle(Vector2(0, 0), 3.0, Color(0.95, 0.15, 0.15))

	# Big Rear Wing
	draw_rect(Rect2(-14, 18, 28, 4), Color(0.85, 0.65, 0.05))
	# F1 rain blinking light
	draw_rect(Rect2(-2, 21, 4, 2), Color(1.0, 0.1, 0.1))

