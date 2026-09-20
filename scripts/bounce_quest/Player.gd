extends CharacterBody2D

signal died
signal bounced(is_high: bool)

const GRAVITY: float = 960.0
const MOVE_SPEED: float = 175.0
const NORMAL_BOUNCE: float = -340.0
const HIGH_BOUNCE: float = -460.0
const HIGH_BOUNCE_BUFFER: float = 0.42

var is_active: bool = true
var is_invulnerable: bool = false
var want_high_bounce: bool = false
var high_bounce_buffer: float = 0.0
var move_dir: float = 0.0
var current_skin_id: String = "classic_red"
var bounce_flash: float = 0.0
var last_bounce_was_high: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("player")
	apply_ball_skin(SaveManager.get_equipped("bounce_ball", "classic_red"))

func apply_ball_skin(skin_id: String):
	current_skin_id = skin_id
	if not sprite:
		return
	match skin_id:
		"neon_pulse":
			sprite.modulate = Color(0.1, 1.0, 0.95)
		"golden_orb":
			sprite.modulate = Color(1.0, 0.85, 0.15)
		_:
			sprite.modulate = Color(1.0, 1.0, 1.0)

func _physics_process(delta: float):
	if not is_active:
		return

	# 1. Apply Gravity
	velocity.y = min(velocity.y + GRAVITY * delta, 650.0)

	# 2. Horizontal Movement
	var input_x = 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_x += 1.0
	
	# Combine with on-screen touch buttons
	if move_dir != 0.0:
		input_x = move_dir

	velocity.x = input_x * MOVE_SPEED

	# 3. Roll ball visually
	if abs(velocity.x) > 5.0:
		sprite.rotation += (velocity.x / 10.0) * delta

	# 4. Check for high bounce input
	high_bounce_buffer = maxf(0.0, high_bounce_buffer - delta)
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		request_high_bounce()
	var jump_pressed := want_high_bounce or high_bounce_buffer > 0.0

	# 5. Move & Slide
	move_and_slide()

	# 6. Automatic Bounce on Floor
	if is_on_floor():
		if jump_pressed:
			velocity.y = HIGH_BOUNCE
			high_bounce_buffer = 0.0
			last_bounce_was_high = true
			bounced.emit(true)
		else:
			velocity.y = NORMAL_BOUNCE
			last_bounce_was_high = false
			bounced.emit(false)
		bounce_flash = 0.18

		# Impact Squash effect
		sprite.scale = Vector2(1.42, 0.62)
	else:
		# Mid-air aerodynamic stretch
		var stretch_y = clamp(1.0 + abs(velocity.y) / 1100.0, 1.0, 1.30)
		var stretch_x = clamp(1.0 / stretch_y, 0.76, 1.0)
		sprite.scale = sprite.scale.lerp(Vector2(stretch_x, stretch_y), 12.0 * delta)

	# Recover scale smoothly
	sprite.scale = sprite.scale.lerp(Vector2.ONE, 14.0 * delta)
	bounce_flash = maxf(0.0, bounce_flash - delta)
	queue_redraw()

	# Fall into bottom abyss
	if position.y > 680.0:
		take_damage()

func _draw():
	# 1. Soft Dynamic Ground Shadow
	var shadow_scale = clamp(1.0 / sprite.scale.y, 0.7, 1.4)
	draw_circle(Vector2(0, 11), 8.5 * shadow_scale, Color(0, 0, 0, 0.25))

	# 2. 3D Radial Specular Glint & Volumetric Highlight
	# Specular Crescent Gleam
	draw_circle(Vector2(-3.5, -3.5), 3.2, Color(1.0, 1.0, 1.0, 0.55))
	draw_circle(Vector2(-4.2, -4.2), 1.4, Color(1.0, 1.0, 1.0, 0.9)) # Hotspot white gleam

	# A quick comic-book impact ring makes every landing feel springy.
	if bounce_flash > 0.0:
		var progress := 1.0 - bounce_flash / 0.18
		var ring_colour := Color(1.0, 0.95, 0.55, 1.0 - progress)
		draw_arc(Vector2(0, 9), 9.0 + progress * 15.0, PI + 0.22, TAU - 0.22, 18, ring_colour, 1.8)
		if last_bounce_was_high:
			draw_line(Vector2(-7, 10), Vector2(-11, 22), ring_colour, 2.0)
			draw_line(Vector2(7, 10), Vector2(11, 22), ring_colour, 2.0)

func set_move_dir(dir: float):
	move_dir = dir

func set_high_bounce(active: bool):
	want_high_bounce = active
	if active:
		request_high_bounce()

func request_high_bounce():
	# A tap can happen shortly before landing; retain it until the next bounce.
	high_bounce_buffer = HIGH_BOUNCE_BUFFER

func take_damage():
	if not is_active or is_invulnerable:
		return

	is_invulnerable = true
	is_active = false
	velocity = Vector2(0.0, -260.0)
	died.emit()

func respawn_at(spawn_pos: Vector2):
	position = spawn_pos
	velocity = Vector2.ZERO
	rotation = 0.0
	sprite.rotation = 0.0
	sprite.scale = Vector2.ONE
	is_active = true
	is_invulnerable = false
	high_bounce_buffer = 0.0
	want_high_bounce = false
	visible = true
