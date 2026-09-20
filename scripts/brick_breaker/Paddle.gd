extends StaticBody2D

var normal_tex = preload("res://assets/brick_breaker/paddle.png")
var wide_tex = preload("res://assets/brick_breaker/paddle_wide.png")

var half_width: float = 32.0
var move_dir: float = 0.0
var target_x: float = 180.0
var wide_timer: float = 0.0

var current_skin_id: String = "classic_cyan"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	position = Vector2(180, 560)
	target_x = position.x
	set_wide(false)
	apply_skin(SaveManager.get_equipped("brick_paddle", "classic_cyan"))

func apply_skin(skin_id: String):
	current_skin_id = skin_id
	if not sprite:
		return
	match skin_id:
		"plasma_blade":
			sprite.modulate = Color(1.0, 0.2, 0.35)
		"golden_ingot":
			sprite.modulate = Color(1.0, 0.85, 0.15)
		"fire_striker":
			sprite.modulate = Color(1.0, 0.5, 0.05)
		_:
			sprite.modulate = Color(0.2, 0.9, 1.0)

func _process(delta: float):
	# 1. Keyboard Input
	var kb_x = 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		kb_x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		kb_x += 1.0

	if move_dir != 0.0:
		kb_x = move_dir

	if kb_x != 0.0:
		target_x += kb_x * 380.0 * delta

	# Clamp to borders
	var min_x = half_width + 12.0
	var max_x = 360.0 - half_width - 12.0
	target_x = clamp(target_x, min_x, max_x)
	position.x = lerp(position.x, target_x, 18.0 * delta)

	# Wide paddle timer
	if wide_timer > 0.0:
		wide_timer -= delta
		if wide_timer <= 0.0:
			set_wide(false)

	# Recover squash scale
	if sprite:
		sprite.scale = sprite.scale.lerp(Vector2.ONE, 14.0 * delta)
	queue_redraw()

func on_hit():
	if sprite:
		sprite.scale = Vector2(1.18, 0.78)

func _draw():
	# Metallic top surface highlight reflection
	draw_line(Vector2(-half_width + 5, -6), Vector2(half_width - 5, -6), Color(1.0, 1.0, 1.0, 0.65), 1.5)
	# Bottom shadow line
	draw_line(Vector2(-half_width + 4, 6), Vector2(half_width - 4, 6), Color(0.0, 0.0, 0.0, 0.35), 1.5)

func _unhandled_input(event: InputEvent):
	# Mouse / Touch Dragging
	if event is InputEventMouseMotion:
		target_x = event.position.x
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		target_x = event.position.x

func set_wide(active: bool):
	if active:
		wide_timer = 12.0
		half_width = 44.0
		sprite.texture = wide_tex
		var shape = collision_shape.shape as RectangleShape2D
		if shape:
			shape.size = Vector2(88, 14)
	else:
		wide_timer = 0.0
		half_width = 32.0
		sprite.texture = normal_tex
		var shape = collision_shape.shape as RectangleShape2D
		if shape:
			shape.size = Vector2(64, 14)

func set_move_dir(dir: float):
	move_dir = dir

func reset():
	target_x = 180.0
	position = Vector2(180, 560)
	set_wide(false)
