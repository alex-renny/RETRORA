extends CharacterBody2D

signal crashed

const GRAVITY: float = 950.0
const JUMP_VELOCITY: float = -320.0
const MAX_FALL_SPEED: float = 620.0

var is_active: bool = false
var is_dead: bool = false
var current_bird_id: String = "yellow_finch"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	velocity = Vector2.ZERO
	rotation = 0.0
	apply_bird(SaveManager.get_equipped("hopper_bird", "yellow_finch"))

func apply_bird(bird_id: String):
	current_bird_id = bird_id
	if sprite:
		sprite.visible = false
	queue_redraw()

func start_flying():
	is_active = true
	is_dead = false
	velocity = Vector2.ZERO
	jump()

func jump():
	if is_dead:
		return
	velocity.y = JUMP_VELOCITY
	rotation = deg_to_rad(-22.0)
	queue_redraw()

func _physics_process(delta: float):
	if not is_active:
		return

	# Apply gravity
	velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	move_and_slide()

	# Smooth nose-dive rotation
	if velocity.y > 0.0:
		var target_rot = deg_to_rad(clamp((velocity.y / MAX_FALL_SPEED) * 70.0, -25.0, 70.0))
		rotation = lerp_angle(rotation, target_rot, 6.0 * delta)

	# Floor and ceiling collision
	if position.y >= 570.0:
		position.y = 570.0
		die()
	elif position.y <= 10.0:
		position.y = 10.0
		velocity.y = 0.0

func die():
	if is_dead:
		return
	is_dead = true
	is_active = false
	velocity = Vector2.ZERO
	crashed.emit()

func reset():
	position = Vector2(80.0, 280.0)
	rotation = 0.0
	velocity = Vector2.ZERO
	is_active = false
	is_dead = false
	queue_redraw()

func _draw():
	match current_bird_id:
		"blue_falcon":
			_draw_blue_falcon()
		"cyber_drone":
			_draw_cyber_drone()
		"pixel_phoenix":
			_draw_pixel_phoenix()
		"midnight_bat":
			_draw_midnight_bat()
		_:
			_draw_yellow_finch()

func _draw_yellow_finch():
	var wing_y = -3.0 if velocity.y < 0 else 2.0
	# Body
	draw_circle(Vector2(0, 0), 10.0, Color(1.0, 0.85, 0.1))
	# Belly
	draw_circle(Vector2(2, 3), 6.0, Color(1.0, 0.95, 0.6))
	# Wing
	draw_polygon(PackedVector2Array([
		Vector2(-7, wing_y),
		Vector2(-1, wing_y - 4),
		Vector2(3, wing_y),
		Vector2(-2, wing_y + 4)
	]), PackedColorArray([Color(0.9, 0.7, 0.05)]))
	# Big Eye
	draw_circle(Vector2(5, -3), 3.5, Color.WHITE)
	draw_circle(Vector2(6, -3), 1.5, Color.BLACK)
	# Beak
	draw_polygon(PackedVector2Array([
		Vector2(8, -2),
		Vector2(14, 0),
		Vector2(8, 3)
	]), PackedColorArray([Color(1.0, 0.45, 0.1)]))

func _draw_blue_falcon():
	var wing_y = -4.0 if velocity.y < 0 else 3.0
	# Body
	draw_circle(Vector2(0, 0), 10.0, Color(0.15, 0.45, 0.95))
	draw_circle(Vector2(2, 3), 6.0, Color(0.7, 0.85, 1.0))
	# Falcon swept wing
	draw_polygon(PackedVector2Array([
		Vector2(-9, wing_y),
		Vector2(1, wing_y - 6),
		Vector2(5, wing_y),
		Vector2(-3, wing_y + 4)
	]), PackedColorArray([Color(0.08, 0.25, 0.65)]))
	# Falcon Eye / Visor
	draw_circle(Vector2(5, -3), 3.0, Color(1.0, 0.8, 0.1))
	draw_circle(Vector2(6, -3), 1.5, Color.BLACK)
	# Curved Falcon Beak
	draw_polygon(PackedVector2Array([
		Vector2(8, -3),
		Vector2(15, -1),
		Vector2(13, 3),
		Vector2(8, 2)
	]), PackedColorArray([Color(1.0, 0.75, 0.0)]))

func _draw_cyber_drone():
	# Hover chassis
	draw_rect(Rect2(-10, -7, 20, 14), Color(0.2, 0.25, 0.35))
	draw_rect(Rect2(-11, -8, 22, 16), Color(0.0, 0.9, 0.9), false, 1.5)
	# Twin thrusters at rear
	draw_rect(Rect2(-13, -6, 3, 4), Color(0.5, 0.5, 0.6))
	draw_rect(Rect2(-13, 2, 3, 4), Color(0.5, 0.5, 0.6))
	# Glowing cyan scanner bar
	draw_rect(Rect2(3, -2, 7, 4), Color(0.0, 1.0, 0.9))
	# Pulse light
	draw_circle(Vector2(-1, 0), 2.5, Color(1.0, 0.2, 0.3))

func _draw_pixel_phoenix():
	var wing_y = -5.0 if velocity.y < 0 else 3.0
	# Fiery Body
	draw_circle(Vector2(0, 0), 10.0, Color(1.0, 0.2, 0.1))
	draw_circle(Vector2(2, 2), 6.0, Color(1.0, 0.65, 0.0))
	# Flame crest on head
	draw_polygon(PackedVector2Array([
		Vector2(-3, -9),
		Vector2(-1, -16),
		Vector2(3, -11),
		Vector2(6, -15),
		Vector2(5, -8)
	]), PackedColorArray([Color(1.0, 0.85, 0.1)]))
	# Fire Wing
	draw_polygon(PackedVector2Array([
		Vector2(-8, wing_y),
		Vector2(0, wing_y - 6),
		Vector2(6, wing_y),
		Vector2(-2, wing_y + 6)
	]), PackedColorArray([Color(1.0, 0.8, 0.0)]))
	# Glowing Eye
	draw_circle(Vector2(5, -3), 3.0, Color(1.0, 1.0, 0.8))
	draw_circle(Vector2(6, -3), 1.5, Color(0.8, 0.1, 0.0))
	# Golden Beak
	draw_polygon(PackedVector2Array([
		Vector2(8, -2),
		Vector2(14, 0),
		Vector2(8, 2)
	]), PackedColorArray([Color(1.0, 0.9, 0.2)]))

func _draw_midnight_bat():
	var wing_y = -6.0 if velocity.y < 0 else 4.0
	# Obsidian bat body
	draw_circle(Vector2(0, 1), 8.0, Color(0.18, 0.12, 0.25))
	# Pointed ears
	draw_polygon(PackedVector2Array([
		Vector2(-5, -6),
		Vector2(-3, -13),
		Vector2(-1, -6)
	]), PackedColorArray([Color(0.28, 0.16, 0.38)]))
	draw_polygon(PackedVector2Array([
		Vector2(1, -6),
		Vector2(3, -13),
		Vector2(5, -6)
	]), PackedColorArray([Color(0.28, 0.16, 0.38)]))
	# Bat wing
	draw_polygon(PackedVector2Array([
		Vector2(-10, wing_y),
		Vector2(-4, wing_y - 7),
		Vector2(2, wing_y - 5),
		Vector2(6, wing_y),
		Vector2(-1, wing_y + 6)
	]), PackedColorArray([Color(0.25, 0.15, 0.35)]))
	# Glowing ruby red eye
	draw_circle(Vector2(4, -1), 2.5, Color(1.0, 0.15, 0.3))

