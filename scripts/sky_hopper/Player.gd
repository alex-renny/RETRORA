extends CharacterBody2D

signal crashed

const GRAVITY: float = 950.0
const JUMP_VELOCITY: float = -320.0
const MAX_FALL_SPEED: float = 620.0

var is_active: bool = false
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	velocity = Vector2.ZERO
	rotation = 0.0

func start_flying():
	is_active = true
	is_dead = false
	velocity = Vector2.ZERO
	jump()

func jump():
	if is_dead:
		return
	velocity.y = JUMP_VELOCITY
	# Quick tilt up
	rotation = deg_to_rad(-22.0)

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
