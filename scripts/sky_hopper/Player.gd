extends CharacterBody2D

signal crashed

const GRAVITY: float = 950.0
const JUMP_VELOCITY: float = -320.0
const MAX_FALL_SPEED: float = 620.0

var is_active: bool = false
var is_dead: bool = false
var current_bird_id: String = "yellow_finch"

var flap_phase: float = 0.0
var blink_timer: float = 0.0
var is_blinking: bool = false

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
	flap_phase = 0.0 # reset flap on tap for immediate upward wing snap
	queue_redraw()

func _physics_process(delta: float):
	# Continuous wing flap animation
	var flap_speed = 24.0 if velocity.y < 0 else 10.0
	if not is_active:
		flap_speed = 6.0
	flap_phase += delta * flap_speed

	# Eye blinking cycle
	blink_timer += delta
	if blink_timer > 3.2:
		is_blinking = true
		if blink_timer > 3.35:
			blink_timer = 0.0
			is_blinking = false

	queue_redraw()

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
	flap_phase = 0.0
	blink_timer = 0.0
	is_blinking = false
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
	var wing_sin = sin(flap_phase)
	var wing_y = wing_sin * 7.0
	var tail_flutter = sin(flap_phase * 0.9) * 2.0

	# 1. Tail Feathers
	draw_polygon(PackedVector2Array([
		Vector2(-7, 2),
		Vector2(-14, 1 + tail_flutter),
		Vector2(-16, 5 + tail_flutter),
		Vector2(-8, 6)
	]), PackedColorArray([Color(0.85, 0.60, 0.05)]))

	# 2. Main Plump Body & Shaded Belly
	draw_circle(Vector2(0, 0), 11.0, Color(0.98, 0.82, 0.12))
	draw_circle(Vector2(2, 3), 7.5, Color(1.0, 0.95, 0.55)) # Soft breast plumage

	# 3. Layered Wing
	var wing_tip_y = wing_y - 8.0 * (1.0 if wing_sin < 0 else 0.4)
	draw_polygon(PackedVector2Array([
		Vector2(-6, wing_y * 0.3),
		Vector2(-1, wing_tip_y),
		Vector2(5, wing_y * 0.3 + 1.0),
		Vector2(1, wing_y * 0.3 + 6.0),
		Vector2(-4, wing_y * 0.3 + 5.0)
	]), PackedColorArray([Color(0.86, 0.62, 0.05)]))
	# Wing inner feather feathering
	draw_line(Vector2(-3, wing_y * 0.3 + 2), Vector2(1, wing_tip_y + 4), Color(1.0, 0.9, 0.3), 1.4)

	# 4. Expressive Eye
	if is_blinking:
		# Happy closed eye curve
		draw_line(Vector2(3, -4), Vector2(7, -2), Color(0.1, 0.1, 0.1), 1.8)
		draw_line(Vector2(7, -2), Vector2(9, -4), Color(0.1, 0.1, 0.1), 1.8)
	else:
		draw_circle(Vector2(6, -3), 4.0, Color.WHITE)
		draw_circle(Vector2(6.8, -3), 2.0, Color(0.08, 0.08, 0.08))
		draw_circle(Vector2(6.0, -4.0), 1.0, Color.WHITE) # Catchlight

	# 5. Beak
	draw_polygon(PackedVector2Array([
		Vector2(9, -2),
		Vector2(16, 0.5),
		Vector2(9, 3.5)
	]), PackedColorArray([Color(0.98, 0.42, 0.1)]))
	draw_line(Vector2(9, 0.5), Vector2(15, 0.5), Color(0.75, 0.25, 0.05), 1.0) # Beak midline

func _draw_blue_falcon():
	var wing_sin = sin(flap_phase)
	var wing_y = wing_sin * 8.0

	# 1. Aerodynamic Tail
	draw_polygon(PackedVector2Array([
		Vector2(-8, 1),
		Vector2(-17, 3 + sin(flap_phase) * 2.0),
		Vector2(-16, 7 + sin(flap_phase) * 2.0),
		Vector2(-8, 4)
	]), PackedColorArray([Color(0.06, 0.18, 0.45)]))

	# 2. Sleek Raptor Body
	draw_circle(Vector2(0, 0), 10.5, Color(0.14, 0.42, 0.92))
	draw_circle(Vector2(2, 3), 6.5, Color(0.72, 0.88, 1.0)) # White chest

	# 3. Sharp Swept Falcon Wing
	var wing_tip = Vector2(-2, wing_y - 9.0)
	draw_polygon(PackedVector2Array([
		Vector2(-8, wing_y * 0.4),
		wing_tip,
		Vector2(6, wing_y * 0.4),
		Vector2(1, wing_y * 0.4 + 6.0),
		Vector2(-6, wing_y * 0.4 + 5.0)
	]), PackedColorArray([Color(0.08, 0.24, 0.60)]))
	# Secondary wing vane
	draw_polygon(PackedVector2Array([
		Vector2(-4, wing_y * 0.4 + 1),
		wing_tip + Vector2(2, 3),
		Vector2(3, wing_y * 0.4 + 2)
	]), PackedColorArray([Color(0.25, 0.55, 0.98)]))

	# 4. Fierce Raptor Eye & Brow
	if is_blinking:
		draw_line(Vector2(4, -3), Vector2(9, -2), Color(0.08, 0.08, 0.15), 2.0)
	else:
		draw_line(Vector2(3, -6), Vector2(9, -3), Color(0.05, 0.15, 0.4), 1.6) # Brow
		draw_circle(Vector2(6, -3), 3.4, Color(1.0, 0.82, 0.15))
		draw_circle(Vector2(6.8, -3), 1.8, Color.BLACK)
		draw_circle(Vector2(6.2, -3.8), 0.9, Color.WHITE)

	# 5. Hooked Raptor Beak
	draw_polygon(PackedVector2Array([
		Vector2(8, -3),
		Vector2(16, -1),
		Vector2(14, 4),
		Vector2(9, 2)
	]), PackedColorArray([Color(1.0, 0.75, 0.05)]))
	# Hook tip
	draw_polygon(PackedVector2Array([
		Vector2(14, -1),
		Vector2(16, -1),
		Vector2(14, 4)
	]), PackedColorArray([Color(0.2, 0.2, 0.2)]))

func _draw_cyber_drone():
	var hover_pulse = sin(flap_phase * 1.5)

	# 1. Twin Thrusters with pulsing plasma flame
	draw_rect(Rect2(-14, -7, 4, 5), Color(0.4, 0.45, 0.55))
	draw_rect(Rect2(-14, 2, 4, 5), Color(0.4, 0.45, 0.55))

	var flame_len = 6.0 + randf_range(0.0, 4.0)
	# Upper thruster flame
	draw_polygon(PackedVector2Array([
		Vector2(-14, -6), Vector2(-14 - flame_len, -4.5), Vector2(-14, -3)
	]), PackedColorArray([Color(0.0, 0.9, 1.0)]))
	# Lower thruster flame
	draw_polygon(PackedVector2Array([
		Vector2(-14, 3), Vector2(-14 - flame_len, 4.5), Vector2(-14, 6)
	]), PackedColorArray([Color(0.0, 0.9, 1.0)]))

	# 2. Sleek Drone Chassis
	draw_rect(Rect2(-10, -8, 20, 16), Color(0.18, 0.22, 0.30))
	draw_rect(Rect2(-11, -9, 22, 18), Color(0.0, 0.95, 0.95), false, 1.5)

	# 3. Rotating Holo Wing Rotor
	var rotor_y = sin(flap_phase * 2.0) * 5.0
	draw_line(Vector2(-6, rotor_y - 4), Vector2(6, rotor_y - 4), Color(0.2, 1.0, 0.9, 0.8), 2.0)

	# 4. Animated Cyan Scanner Visor
	var scan_sweep = sin(Time.get_ticks_msec() * 0.008) * 3.0
	draw_rect(Rect2(3, -3, 8, 6), Color(0.05, 0.05, 0.1))
	draw_rect(Rect2(4 + scan_sweep, -2, 3, 4), Color(0.0, 1.0, 0.85))

func _draw_pixel_phoenix():
	var wing_sin = sin(flap_phase)
	var wing_y = wing_sin * 9.0

	# 1. Trailing Fire Plumes
	for p_idx in range(3):
		var p_offset = -12.0 - float(p_idx) * 4.0
		var p_wave = sin(flap_phase * 1.4 + p_idx) * 3.5
		draw_circle(Vector2(p_offset, 2.0 + p_wave), 5.0 - p_idx * 1.2, Color(1.0, 0.45 - p_idx * 0.15, 0.05, 0.75))

	# 2. Glowing Fiery Body
	draw_circle(Vector2(0, 0), 11.0, Color(0.98, 0.22, 0.08))
	draw_circle(Vector2(2, 2), 7.0, Color(1.0, 0.75, 0.1))

	# 3. Head Flame Crest
	var crest_flicker = sin(Time.get_ticks_msec() * 0.02) * 2.0
	draw_polygon(PackedVector2Array([
		Vector2(-4, -9),
		Vector2(-2, -18 + crest_flicker),
		Vector2(2, -12),
		Vector2(7, -17 - crest_flicker),
		Vector2(6, -8)
	]), PackedColorArray([Color(1.0, 0.88, 0.15)]))

	# 4. Radiant Flame Wings
	var wing_tip = Vector2(0, wing_y - 11.0)
	draw_polygon(PackedVector2Array([
		Vector2(-8, wing_y * 0.3),
		wing_tip,
		Vector2(7, wing_y * 0.3),
		Vector2(1, wing_y * 0.3 + 7.0),
		Vector2(-5, wing_y * 0.3 + 5.0)
	]), PackedColorArray([Color(1.0, 0.75, 0.05)]))
	draw_polygon(PackedVector2Array([
		Vector2(-4, wing_y * 0.3),
		wing_tip + Vector2(1, 3),
		Vector2(4, wing_y * 0.3)
	]), PackedColorArray([Color(1.0, 0.95, 0.4)]))

	# 5. Glowing Eye & Beak
	if is_blinking:
		draw_line(Vector2(4, -3), Vector2(8, -2), Color(0.3, 0.05, 0.0), 1.8)
	else:
		draw_circle(Vector2(6, -3), 3.4, Color(1.0, 1.0, 0.85))
		draw_circle(Vector2(6.8, -3), 1.7, Color(0.85, 0.1, 0.0))
		draw_circle(Vector2(6.2, -3.7), 0.8, Color.WHITE)

	draw_polygon(PackedVector2Array([
		Vector2(9, -2), Vector2(16, 0), Vector2(9, 2.5)
	]), PackedColorArray([Color(1.0, 0.92, 0.25)]))

func _draw_midnight_bat():
	var wing_sin = sin(flap_phase)
	var wing_y = wing_sin * 10.0

	# 1. Bat Body
	draw_circle(Vector2(0, 1), 9.0, Color(0.18, 0.12, 0.26))

	# 2. Pointed Velvet Ears
	draw_polygon(PackedVector2Array([
		Vector2(-5, -6), Vector2(-3, -15), Vector2(-1, -6)
	]), PackedColorArray([Color(0.28, 0.16, 0.38)]))
	draw_polygon(PackedVector2Array([
		Vector2(1, -6), Vector2(3, -15), Vector2(5, -6)
	]), PackedColorArray([Color(0.28, 0.16, 0.38)]))
	# Inner ear pink
	draw_polygon(PackedVector2Array([
		Vector2(-4, -6), Vector2(-3, -12), Vector2(-2, -6)
	]), PackedColorArray([Color(0.85, 0.45, 0.65)]))
	draw_polygon(PackedVector2Array([
		Vector2(2, -6), Vector2(3, -12), Vector2(4, -6)
	]), PackedColorArray([Color(0.85, 0.45, 0.65)]))

	# 3. Membrane Wing Fingers
	var w_tip1 = Vector2(-10, wing_y - 4)
	var w_tip2 = Vector2(-3, wing_y - 9)
	var w_tip3 = Vector2(4, wing_y - 6)
	draw_polygon(PackedVector2Array([
		Vector2(-5, 0),
		w_tip1,
		w_tip2,
		w_tip3,
		Vector2(6, 2),
		Vector2(-1, wing_y * 0.3 + 6.0)
	]), PackedColorArray([Color(0.26, 0.15, 0.36)]))

	# 4. Glowing Ruby Eye & Cute Fangs
	if is_blinking:
		draw_line(Vector2(3, -2), Vector2(7, -1), Color(0.1, 0.05, 0.15), 1.8)
	else:
		draw_circle(Vector2(5, -1), 2.8, Color(1.0, 0.15, 0.35))
		draw_circle(Vector2(5.5, -1.6), 0.9, Color.WHITE)

	# Tiny White Fangs
	draw_line(Vector2(7, 3), Vector2(7, 5), Color.WHITE, 1.2)
	draw_line(Vector2(9, 3), Vector2(9, 5), Color.WHITE, 1.2)
