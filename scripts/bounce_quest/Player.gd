extends CharacterBody2D

signal died
signal bounced(is_high: bool)

const GRAVITY: float = 960.0
const MOVE_SPEED: float = 175.0
const NORMAL_BOUNCE: float = -340.0
const HIGH_BOUNCE: float = -460.0

var is_active: bool = true
var is_invulnerable: bool = false
var want_high_bounce: bool = false
var move_dir: float = 0.0
var current_skin_id: String = "classic_red"

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
	var jump_pressed = want_high_bounce or Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)

	# 5. Move & Slide
	move_and_slide()

	# 6. Automatic Bounce on Floor
	if is_on_floor():
		if jump_pressed:
			velocity.y = HIGH_BOUNCE
			bounced.emit(true)
		else:
			velocity.y = NORMAL_BOUNCE
			bounced.emit(false)

		# Squash effect on impact
		sprite.scale = Vector2(1.35, 0.7)
	else:
		# Stretch in mid-air
		var stretch_y = clamp(1.0 + abs(velocity.y) / 1200.0, 1.0, 1.25)
		var stretch_x = clamp(1.0 / stretch_y, 0.8, 1.0)
		sprite.scale = sprite.scale.lerp(Vector2(stretch_x, stretch_y), 10.0 * delta)

	# Recover scale smoothly
	sprite.scale = sprite.scale.lerp(Vector2.ONE, 12.0 * delta)

	# Fall into bottom abyss
	if position.y > 680.0:
		take_damage()

func set_move_dir(dir: float):
	move_dir = dir

func set_high_bounce(active: bool):
	want_high_bounce = active

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
	visible = true
