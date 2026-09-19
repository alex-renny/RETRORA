extends CharacterBody2D

signal ball_lost(ball_node)

const BASE_SPEED: float = 320.0
const MAX_SPEED: float = 460.0

var current_speed: float = BASE_SPEED
var is_stuck_to_paddle: bool = true
var paddle_ref: Node2D = null
var current_style_id: String = "silver_sphere"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("balls")
	apply_ball_style(SaveManager.get_equipped("brick_ball", "silver_sphere"))

func apply_ball_style(style_id: String):
	current_style_id = style_id
	if not sprite:
		return
	match style_id:
		"fireball_comet":
			sprite.modulate = Color(1.0, 0.45, 0.1)
		"neon_prism":
			sprite.modulate = Color(0.9, 0.2, 1.0)
		_:
			sprite.modulate = Color(1.0, 1.0, 1.0)

func stick_to_paddle(p: Node2D):
	paddle_ref = p
	is_stuck_to_paddle = true
	velocity = Vector2.ZERO
	current_speed = BASE_SPEED
	visible = true

func launch():
	if not is_stuck_to_paddle:
		return
	is_stuck_to_paddle = false
	var launch_dir = Vector2(randf_range(-0.25, 0.25), -1.0).normalized()
	velocity = launch_dir * current_speed

func set_slow():
	current_speed = max(BASE_SPEED * 0.75, current_speed - 80.0)
	if velocity.length() > 0:
		velocity = velocity.normalized() * current_speed

func _physics_process(delta: float):
	if is_stuck_to_paddle and paddle_ref and is_instance_valid(paddle_ref):
		position = paddle_ref.position + Vector2(0, -14)
		return

	# Wall bouncing safety
	if position.x <= 14.0 and velocity.x < 0:
		velocity.x = abs(velocity.x)
	elif position.x >= 346.0 and velocity.x > 0:
		velocity.x = -abs(velocity.x)
	if position.y <= 44.0 and velocity.y < 0:
		velocity.y = abs(velocity.y)

	# Bottom pit check
	if position.y >= 630.0:
		ball_lost.emit(self)
		return

	# Physics movement & collision resolution
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()

		if collider and collider.has_method("set_wide"):
			# Struck the Paddle! Compute dynamic angle
			var half_w = 32.0
			if "half_width" in collider:
				half_w = collider.half_width

			var hit_offset = clamp((position.x - collider.position.x) / half_w, -1.0, 1.0)
			var bounce_angle = hit_offset * deg_to_rad(65.0)
			velocity = Vector2(sin(bounce_angle), -cos(bounce_angle)) * current_speed
		elif collider and collider.has_method("hit"):
			# Struck a Brick!
			collider.hit()
			velocity = velocity.bounce(collision.get_normal())
			current_speed = min(MAX_SPEED, current_speed + 2.0)
			velocity = velocity.normalized() * current_speed
		else:
			# Wall or obstacle bounce
			velocity = velocity.bounce(collision.get_normal())

		# Prevent dead horizontal bouncing
		if abs(velocity.y) < 40.0:
			velocity.y = -60.0 if velocity.y < 0 else 60.0
			velocity = velocity.normalized() * current_speed
