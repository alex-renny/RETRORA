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

	# Dynamic steering banking / lean roll angle
	var diff_x = target_x - position.x
	var target_rot = clamp(diff_x * 0.22, -14.0, 14.0)
	rotation_degrees = lerp(rotation_degrees, target_rot, 14.0 * delta)

	queue_redraw()

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

func set_drag_target_x(screen_x: float) -> void:
	if not is_active:
		return
	# Follow the finger inside the road while retaining lane-aware button input.
	target_x = clampf(screen_x, LANE_POSITIONS[0], LANE_POSITIONS[2])
	current_lane = clampi(int(round((target_x - LANE_POSITIONS[0]) / 70.0)), 0, LANE_POSITIONS.size() - 1)

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
	rotation_degrees = 0.0
	is_active = true
	visible = true

func _draw():
	# Ground drop shadow
	draw_circle(Vector2(0, 3), 16.0, Color(0, 0, 0, 0.35))

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

func _draw_flame(pos: Vector2, color: Color, length: float):
	draw_polygon(PackedVector2Array([
		pos + Vector2(-2, 0),
		pos + Vector2(0, length),
		pos + Vector2(2, 0)
	]), PackedColorArray([color]))
	draw_polygon(PackedVector2Array([
		pos + Vector2(-1, 0),
		pos + Vector2(0, length * 0.55),
		pos + Vector2(1, 0)
	]), PackedColorArray([Color.WHITE]))

func _draw_red_racer():
	var fl = 6.0 + randf_range(0.0, 6.0)
	# Twin Nitro exhaust flames
	_draw_flame(Vector2(-5, 18), Color(0.1, 0.8, 1.0), fl)
	_draw_flame(Vector2(5, 18), Color(0.1, 0.8, 1.0), fl)

	# Wheels
	var wheel_col = Color(0.12, 0.12, 0.14)
	draw_rect(Rect2(-12, -16, 4, 9), wheel_col)
	draw_rect(Rect2(8, -16, 4, 9), wheel_col)
	draw_rect(Rect2(-12, 8, 4, 9), wheel_col)
	draw_rect(Rect2(8, 8, 4, 9), wheel_col)

	# Body
	draw_rect(Rect2(-9, -19, 18, 38), Color(0.90, 0.15, 0.18))
	draw_rect(Rect2(-8, -18, 16, 36), Color(0.98, 0.22, 0.22))
	# Racing Stripe
	draw_rect(Rect2(-2, -19, 4, 38), Color.WHITE)

	# Windshield & Roof
	draw_rect(Rect2(-6, -7, 12, 11), Color(0.08, 0.14, 0.22))
	# Windshield diagonal glare streak
	draw_line(Vector2(-5, -6), Vector2(3, 2), Color(0.5, 0.8, 1.0, 0.6), 1.5)
	draw_rect(Rect2(-5, -2, 10, 6), Color(0.85, 0.12, 0.16))

	# Headlights & Taillights
	draw_rect(Rect2(-8, -20, 4, 2), Color(1.0, 0.98, 0.6))
	draw_rect(Rect2(4, -20, 4, 2), Color(1.0, 0.98, 0.6))
	draw_rect(Rect2(-8, 18, 4, 2), Color(1.0, 0.15, 0.1))
	draw_rect(Rect2(4, 18, 4, 2), Color(1.0, 0.15, 0.1))

func _draw_superbike():
	var fl = 7.0 + randf_range(0.0, 7.0)
	_draw_flame(Vector2(0, 17), Color(1.0, 0.45, 0.1), fl)

	# Tires
	draw_rect(Rect2(-3, -17, 6, 10), Color(0.1, 0.1, 0.12))
	draw_rect(Rect2(-3, 8, 6, 10), Color(0.1, 0.1, 0.12))

	# Cyan/Neon Frame & Fairings
	draw_rect(Rect2(-5, -11, 10, 22), Color(0.0, 0.92, 0.65))
	draw_line(Vector2(-8, -11), Vector2(8, -11), Color(0.85, 0.85, 0.85), 2.2)

	# Rider leaning with handlebars
	draw_circle(Vector2(0, -1), 4.5, Color(1.0, 0.85, 0.15)) # Helmet
	draw_line(Vector2(-3, -2), Vector2(3, -2), Color(0.1, 0.1, 0.15), 1.6) # Visor
	draw_rect(Rect2(-4, 3, 8, 6), Color(0.15, 0.18, 0.25)) # Leather Jacket

	# Headlight & Taillight
	draw_rect(Rect2(-2, -18, 4, 2), Color(1.0, 1.0, 0.8))
	draw_rect(Rect2(-2, 17, 4, 2), Color(1.0, 0.2, 0.1))

func _draw_muscle_cruiser():
	var fl = 8.0 + randf_range(0.0, 8.0)
	_draw_flame(Vector2(-7, 20), Color(1.0, 0.35, 0.05), fl)
	_draw_flame(Vector2(7, 20), Color(1.0, 0.35, 0.05), fl)

	# Wide Drag Slicks
	var wheel_col = Color(0.1, 0.1, 0.12)
	draw_rect(Rect2(-13, -16, 5, 10), wheel_col)
	draw_rect(Rect2(8, -16, 5, 10), wheel_col)
	draw_rect(Rect2(-14, 8, 6, 11), wheel_col)
	draw_rect(Rect2(8, 8, 6, 11), wheel_col)

	# Plum Purple Metallic Muscle Body
	draw_rect(Rect2(-10, -21, 20, 42), Color(0.28, 0.10, 0.50))
	draw_rect(Rect2(-9, -20, 18, 40), Color(0.35, 0.14, 0.60))

	# Dual Silver Racing Stripes
	draw_line(Vector2(-3, -21), Vector2(-3, 21), Color(0.9, 0.9, 0.95), 1.6)
	draw_line(Vector2(3, -21), Vector2(3, 21), Color(0.9, 0.9, 0.95), 1.6)

	# Big Chrome Blower with Butterflies
	draw_rect(Rect2(-4, -16, 8, 6), Color(0.88, 0.92, 0.98))
	draw_circle(Vector2(-2, -15), 1.2, Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(2, -15), 1.2, Color(0.9, 0.1, 0.1))

	# Dark Tinted Glass with Specular Glare
	draw_rect(Rect2(-7, -8, 14, 13), Color(0.07, 0.07, 0.14))
	draw_line(Vector2(-6, -7), Vector2(4, 3), Color(0.6, 0.7, 0.9, 0.5), 1.5)

	# Rear Spoiler & Lights
	draw_rect(Rect2(-11, 19, 22, 3), Color(0.18, 0.05, 0.35))
	draw_rect(Rect2(-9, -22, 4, 2), Color(1.0, 0.95, 0.4))
	draw_rect(Rect2(5, -22, 4, 2), Color(1.0, 0.95, 0.4))
	draw_rect(Rect2(-9, 20, 4, 2), Color(1.0, 0.1, 0.2))
	draw_rect(Rect2(5, 20, 4, 2), Color(1.0, 0.1, 0.2))

func _draw_turbo_bus():
	var fl = 6.0 + randf_range(0.0, 5.0)
	_draw_flame(Vector2(0, 26), Color(1.0, 0.5, 0.1), fl)

	var wheel_col = Color(0.1, 0.1, 0.12)
	draw_rect(Rect2(-13, -20, 3, 10), wheel_col)
	draw_rect(Rect2(10, -20, 3, 10), wheel_col)
	draw_rect(Rect2(-13, 12, 3, 10), wheel_col)
	draw_rect(Rect2(10, 12, 3, 10), wheel_col)

	# Bus Body
	draw_rect(Rect2(-12, -27, 24, 54), Color(0.96, 0.62, 0.05))
	draw_rect(Rect2(-11, -26, 22, 52), Color(1.0, 0.72, 0.15))

	# Panoramic Windshield
	draw_rect(Rect2(-9, -24, 18, 8), Color(0.15, 0.65, 0.88))
	draw_line(Vector2(-7, -23), Vector2(5, -18), Color(0.7, 0.9, 1.0, 0.6), 1.5)

	# Side Windows
	for wy in [-12, -3, 6, 15]:
		draw_rect(Rect2(-10, wy, 4, 6), Color(0.15, 0.65, 0.88))
		draw_rect(Rect2(6, wy, 4, 6), Color(0.15, 0.65, 0.88))

	# Roof AC Units
	draw_rect(Rect2(-4, -6, 8, 14), Color(0.85, 0.55, 0.05))

	# Lights
	draw_rect(Rect2(-10, -28, 4, 2), Color(1.0, 1.0, 0.7))
	draw_rect(Rect2(6, -28, 4, 2), Color(1.0, 1.0, 0.7))
	draw_rect(Rect2(-10, 26, 4, 2), Color(1.0, 0.15, 0.1))
	draw_rect(Rect2(6, 26, 4, 2), Color(1.0, 0.15, 0.1))

func _draw_golden_f1():
	var fl = 9.0 + randf_range(0.0, 7.0)
	_draw_flame(Vector2(0, 19), Color(0.2, 0.7, 1.0), fl)

	# Wide F1 Slicks
	var tire_col = Color(0.1, 0.1, 0.12)
	draw_rect(Rect2(-15, -16, 6, 9), tire_col)
	draw_rect(Rect2(9, -16, 6, 9), tire_col)
	draw_rect(Rect2(-16, 9, 7, 11), tire_col)
	draw_rect(Rect2(9, 9, 7, 11), tire_col)

	# Front Aerodynamic Wing
	draw_rect(Rect2(-14, -22, 28, 5), Color(0.85, 0.70, 0.05))

	# Needle Fuselage & Sidepods
	draw_polygon(PackedVector2Array([
		Vector2(0, -22),
		Vector2(-4, -10),
		Vector2(-8, 2),
		Vector2(-8, 18),
		Vector2(8, 18),
		Vector2(8, 2),
		Vector2(4, -10)
	]), PackedColorArray([Color(1.0, 0.85, 0.05)]))
	draw_line(Vector2(0, -20), Vector2(0, 16), Color(1.0, 1.0, 0.6), 1.6)

	# Open Cockpit & Driver Helmet
	draw_rect(Rect2(-4, -4, 8, 8), Color(0.06, 0.06, 0.08))
	draw_circle(Vector2(0, 0), 3.4, Color(0.95, 0.2, 0.2)) # Helmet
	draw_line(Vector2(-2, -1), Vector2(2, -1), Color(0.1, 0.1, 0.1), 1.4) # Visor

	# Big Rear Aerodynamic Wing
	draw_rect(Rect2(-15, 18, 30, 4), Color(0.85, 0.65, 0.05))
	# F1 rain flashing LED
	var led_blink = sin(Time.get_ticks_msec() * 0.02) > 0.0
	draw_rect(Rect2(-2, 21, 4, 2), Color(1.0, 0.1, 0.1) if led_blink else Color(0.4, 0.05, 0.05))
