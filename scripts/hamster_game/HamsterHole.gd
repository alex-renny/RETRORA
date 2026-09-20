extends Control

# HamsterHole manages an individual burrow and hamster lifecycle in the 3x3 grid.

signal hole_whacked(hole_index: int, hamster_type: int)

enum State { EMPTY, EMERGING, PEEKING, BURROWING, WHACKED }
enum HamsterType { NORMAL, GOLDEN, BOMB }

var hole_index: int = 0
var current_state: State = State.EMPTY
var hamster_type: HamsterType = HamsterType.NORMAL
var current_animal_id: String = "hamster"

var emerge_progress: float = 0.0 # 0.0 = deep inside hole, 1.0 = fully raised
var peek_timer: float = 0.0
var peek_duration: float = 1.0
var dizzy_timer: float = 0.0
var star_angle: float = 0.0

# Floating score feedback
var float_score_text: String = ""
var float_score_color: Color = Color.YELLOW
var float_score_timer: float = 0.0
var float_score_pos_y: float = 0.0

@onready var hit_button: Button = $HitButton
@onready var score_label: Label = $ScoreLabel

func _ready():
	hit_button.pressed.connect(_on_button_pressed)
	score_label.visible = false
	apply_animal_type(SaveManager.get_equipped("hamster_animal", "hamster"))

func apply_animal_type(animal_id: String):
	current_animal_id = animal_id
	queue_redraw()

func spawn(type: int, duration: float):
	if current_state != State.EMPTY:
		return
	hamster_type = type as HamsterType
	peek_duration = max(0.45, duration)
	emerge_progress = 0.0
	current_state = State.EMERGING
	queue_redraw()

func try_whack() -> bool:
	if current_state == State.EMERGING or current_state == State.PEEKING:
		current_state = State.WHACKED
		dizzy_timer = 0.45
		hole_whacked.emit(hole_index, hamster_type)
		queue_redraw()
		return true
	return false

func show_floating_score(text: String, color: Color):
	float_score_text = text
	float_score_color = color
	float_score_timer = 0.8
	float_score_pos_y = -35.0
	score_label.text = text
	score_label.modulate = color
	score_label.visible = true

func _on_button_pressed():
	try_whack()

func _process(delta: float):
	if current_state == State.EMERGING:
		emerge_progress = min(1.0, emerge_progress + delta * 6.5)
		if emerge_progress >= 1.0:
			emerge_progress = 1.0
			current_state = State.PEEKING
			peek_timer = peek_duration
		queue_redraw()

	elif current_state == State.PEEKING:
		peek_timer -= delta
		if peek_timer <= 0.0:
			current_state = State.BURROWING
		queue_redraw()

	elif current_state == State.BURROWING:
		emerge_progress = max(0.0, emerge_progress - delta * 6.0)
		if emerge_progress <= 0.0:
			emerge_progress = 0.0
			current_state = State.EMPTY
		queue_redraw()

	elif current_state == State.WHACKED:
		dizzy_timer -= delta
		star_angle += delta * 14.0
		if dizzy_timer <= 0.0:
			current_state = State.BURROWING
		queue_redraw()

	# Floating score animation
	if float_score_timer > 0.0:
		float_score_timer -= delta
		float_score_pos_y -= delta * 35.0
		score_label.position.y = float_score_pos_y
		score_label.modulate.a = clamp(float_score_timer / 0.8, 0.0, 1.0)
		if float_score_timer <= 0.0:
			score_label.visible = false

func _draw():
	var center = Vector2(48, 48)

	# 1. Back Dirt Mound (Outer rim)
	_draw_dirt_mound_back(center)

	# 2. Dark Burrow Hole
	var hole_rect = Rect2(center.x - 30, center.y - 10, 60, 20)
	_draw_oval(hole_rect, Color(0.22, 0.12, 0.06))

	# 3. Animal Character (Pops out between back and front mound)
	if current_state != State.EMPTY:
		var breath = sin(Time.get_ticks_msec() * 0.006) * 1.2 if current_state == State.PEEKING else 0.0
		var pop_y = lerp(12.0, -18.0, emerge_progress) + breath
		if current_state == State.WHACKED:
			pop_y += 5.0 # Flattened slightly on impact
		var animal_center = center + Vector2(0, pop_y)
		_draw_animal(animal_center)

	# 4. Front Dirt Mound Lip (Occludes bottom of animal so it emerges naturally)
	_draw_dirt_mound_front(center)

	# 5. Whacked Effects (Dizzy spinning stars)
	if current_state == State.WHACKED:
		var pop_y = lerp(12.0, -18.0, emerge_progress) + 5.0
		var head_center = center + Vector2(0, pop_y - 20)
		_draw_dizzy_stars(head_center)

func _draw_oval(rect: Rect2, color: Color):
	var points = PackedVector2Array()
	var center = rect.get_center()
	var rx = rect.size.x * 0.5
	var ry = rect.size.y * 0.5
	for i in range(16):
		var ang = (float(i) / 16.0) * TAU
		points.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(points, color)

func _draw_dirt_mound_back(c: Vector2):
	var mound_pts = PackedVector2Array([
		c + Vector2(-44, 4),
		c + Vector2(-36, -8),
		c + Vector2(-20, -14),
		c + Vector2(0, -16),
		c + Vector2(20, -14),
		c + Vector2(36, -8),
		c + Vector2(44, 4),
		c + Vector2(40, 16),
		c + Vector2(-40, 16)
	])
	draw_colored_polygon(mound_pts, Color(0.85, 0.62, 0.28))
	draw_circle(c + Vector2(-26, -6), 2.5, Color(0.72, 0.50, 0.20))
	draw_circle(c + Vector2(28, -5), 2.0, Color(0.72, 0.50, 0.20))

func _draw_dirt_mound_front(c: Vector2):
	var front_pts = PackedVector2Array([
		c + Vector2(-44, 4),
		c + Vector2(-32, 2),
		c + Vector2(-16, 4),
		c + Vector2(0, 5),
		c + Vector2(16, 4),
		c + Vector2(32, 2),
		c + Vector2(44, 4),
		c + Vector2(40, 18),
		c + Vector2(24, 16),
		c + Vector2(0, 19),
		c + Vector2(-24, 16),
		c + Vector2(-40, 18)
	])
	draw_colored_polygon(front_pts, Color(0.88, 0.65, 0.30))
	draw_polyline(PackedVector2Array([
		c + Vector2(-44, 4),
		c + Vector2(-16, 4),
		c + Vector2(0, 5),
		c + Vector2(16, 4),
		c + Vector2(44, 4)
	]), Color(0.72, 0.50, 0.20), 1.5)

func _draw_animal(pos: Vector2):
	match current_animal_id:
		"bunny":
			_draw_bunny(pos)
		"kitty":
			_draw_kitty(pos)
		"panda":
			_draw_panda(pos)
		"fox":
			_draw_fox(pos)
		_:
			_draw_hamster(pos)

	_draw_accessories(pos)

func _draw_hamster(pos: Vector2):
	var body_col = Color(0.93, 0.66, 0.38)
	var inner_ear_col = Color(0.98, 0.58, 0.72)
	var belly_col = Color(0.99, 0.94, 0.85)

	if hamster_type == HamsterType.GOLDEN:
		body_col = Color(1.0, 0.84, 0.15)
		belly_col = Color(1.0, 0.96, 0.75)
	elif hamster_type == HamsterType.BOMB:
		body_col = Color(0.42, 0.40, 0.48)
		belly_col = Color(0.65, 0.60, 0.68)

	# Ears
	draw_circle(pos + Vector2(-14, -18), 6.5, body_col)
	draw_circle(pos + Vector2(14, -18), 6.5, body_col)
	draw_circle(pos + Vector2(-14, -18), 3.5, inner_ear_col)
	draw_circle(pos + Vector2(14, -18), 3.5, inner_ear_col)

	# Head / Body
	var body_rect = Rect2(pos.x - 19, pos.y - 20, 38, 34)
	_draw_oval(body_rect, body_col)

	# Snout
	var belly_rect = Rect2(pos.x - 12, pos.y - 8, 24, 20)
	_draw_oval(belly_rect, belly_col)

	# Eyes
	_draw_eyes(pos)

	# Cheeks & Whiskers
	draw_circle(pos + Vector2(-14, -4), 4.0, Color(1.0, 0.5, 0.6, 0.55))
	draw_circle(pos + Vector2(14, -4), 4.0, Color(1.0, 0.5, 0.6, 0.55))
	draw_circle(pos + Vector2(0, -6), 2.2, Color(0.25, 0.12, 0.08))
	_draw_whiskers(pos)

	# Buck Teeth
	draw_rect(Rect2(pos.x - 2.5, pos.y - 3.5, 2.2, 4.0), Color.WHITE)
	draw_rect(Rect2(pos.x + 0.3, pos.y - 3.5, 2.2, 4.0), Color.WHITE)

	# Paws
	draw_circle(pos + Vector2(-10, 6), 3.2, belly_col)
	draw_circle(pos + Vector2(10, 6), 3.2, belly_col)

func _draw_bunny(pos: Vector2):
	var body_col = Color(0.96, 0.96, 0.98)
	var inner_ear_col = Color(1.0, 0.68, 0.78)
	if hamster_type == HamsterType.GOLDEN:
		body_col = Color(1.0, 0.88, 0.25)
	elif hamster_type == HamsterType.BOMB:
		body_col = Color(0.38, 0.38, 0.45)

	# Tall Bunny Ears
	_draw_oval(Rect2(pos.x - 15, pos.y - 36, 10, 24), body_col)
	_draw_oval(Rect2(pos.x + 5, pos.y - 36, 10, 24), body_col)
	_draw_oval(Rect2(pos.x - 13, pos.y - 34, 6, 18), inner_ear_col)
	_draw_oval(Rect2(pos.x + 7, pos.y - 34, 6, 18), inner_ear_col)

	# Head
	_draw_oval(Rect2(pos.x - 18, pos.y - 18, 36, 32), body_col)
	_draw_eyes(pos)

	# Pink Nose & Whiskers
	draw_polygon(PackedVector2Array([
		pos + Vector2(-2.5, -6),
		pos + Vector2(2.5, -6),
		pos + Vector2(0, -3.5)
	]), PackedColorArray([inner_ear_col]))
	_draw_whiskers(pos)
	draw_circle(pos + Vector2(-13, -3), 3.5, Color(1.0, 0.5, 0.6, 0.5))
	draw_circle(pos + Vector2(13, -3), 3.5, Color(1.0, 0.5, 0.6, 0.5))

	# Fluffy Paws
	draw_circle(pos + Vector2(-9, 6), 3.5, Color.WHITE)
	draw_circle(pos + Vector2(9, 6), 3.5, Color.WHITE)

func _draw_kitty(pos: Vector2):
	var body_col = Color(0.96, 0.68, 0.36)
	var inner_ear_col = Color(0.98, 0.6, 0.7)
	if hamster_type == HamsterType.GOLDEN:
		body_col = Color(1.0, 0.84, 0.15)
	elif hamster_type == HamsterType.BOMB:
		body_col = Color(0.4, 0.38, 0.46)

	# Pointed Cat Ears
	draw_polygon(PackedVector2Array([
		pos + Vector2(-18, -12),
		pos + Vector2(-12, -26),
		pos + Vector2(-5, -15)
	]), PackedColorArray([body_col]))
	draw_polygon(PackedVector2Array([
		pos + Vector2(5, -15),
		pos + Vector2(12, -26),
		pos + Vector2(18, -12)
	]), PackedColorArray([body_col]))
	draw_polygon(PackedVector2Array([
		pos + Vector2(-15, -13),
		pos + Vector2(-12, -23),
		pos + Vector2(-7, -15)
	]), PackedColorArray([inner_ear_col]))
	draw_polygon(PackedVector2Array([
		pos + Vector2(7, -15),
		pos + Vector2(12, -23),
		pos + Vector2(15, -13)
	]), PackedColorArray([inner_ear_col]))

	# Head
	_draw_oval(Rect2(pos.x - 18, pos.y - 18, 36, 32), body_col)
	_draw_eyes(pos)

	# Kitty Snout & Whiskers
	draw_circle(pos + Vector2(0, -6), 2.0, inner_ear_col)
	_draw_whiskers(pos)
	# Cat smile 'w'
	draw_line(pos + Vector2(-3, -3), pos + Vector2(0, -4), Color(0.3, 0.2, 0.2), 1.2)
	draw_line(pos + Vector2(0, -4), pos + Vector2(3, -3), Color(0.3, 0.2, 0.2), 1.2)

	# Paws
	draw_circle(pos + Vector2(-9, 6), 3.2, Color(0.99, 0.94, 0.88))
	draw_circle(pos + Vector2(9, 6), 3.2, Color(0.99, 0.94, 0.88))

func _draw_panda(pos: Vector2):
	var body_col = Color(0.98, 0.98, 1.0)
	var black_col = Color(0.12, 0.12, 0.15)
	if hamster_type == HamsterType.GOLDEN:
		body_col = Color(1.0, 0.92, 0.5)
		black_col = Color(0.8, 0.6, 0.1)
	elif hamster_type == HamsterType.BOMB:
		body_col = Color(0.5, 0.5, 0.58)
		black_col = Color(0.2, 0.2, 0.25)

	# Round Black Ears
	draw_circle(pos + Vector2(-14, -17), 6.5, black_col)
	draw_circle(pos + Vector2(14, -17), 6.5, black_col)

	# White Head
	_draw_oval(Rect2(pos.x - 18, pos.y - 18, 36, 32), body_col)

	# Black Eye Patches
	_draw_oval(Rect2(pos.x - 13, pos.y - 14, 10, 8), black_col)
	_draw_oval(Rect2(pos.x + 3, pos.y - 14, 10, 8), black_col)

	# Eyes
	if current_state == State.WHACKED:
		_draw_x_eye(pos + Vector2(-8, -10))
		_draw_x_eye(pos + Vector2(8, -10))
	else:
		draw_circle(pos + Vector2(-8, -10), 2.0, Color.WHITE)
		draw_circle(pos + Vector2(8, -10), 2.0, Color.WHITE)
		draw_circle(pos + Vector2(-8, -10), 1.0, Color.BLACK)
		draw_circle(pos + Vector2(8, -10), 1.0, Color.BLACK)

	# Panda Nose
	_draw_oval(Rect2(pos.x - 3, pos.y - 6, 6, 4), black_col)

	# Black Paws
	draw_circle(pos + Vector2(-10, 6), 3.5, black_col)
	draw_circle(pos + Vector2(10, 6), 3.5, black_col)

func _draw_fox(pos: Vector2):
	var body_col = Color(0.92, 0.45, 0.15)
	var white_col = Color(0.98, 0.98, 1.0)
	var black_col = Color(0.15, 0.15, 0.18)
	if hamster_type == HamsterType.GOLDEN:
		body_col = Color(1.0, 0.82, 0.1)
	elif hamster_type == HamsterType.BOMB:
		body_col = Color(0.4, 0.35, 0.48)

	# Pointed Fox Ears
	draw_polygon(PackedVector2Array([
		pos + Vector2(-17, -12),
		pos + Vector2(-12, -26),
		pos + Vector2(-5, -15)
	]), PackedColorArray([black_col]))
	draw_polygon(PackedVector2Array([
		pos + Vector2(5, -15),
		pos + Vector2(12, -26),
		pos + Vector2(17, -12)
	]), PackedColorArray([black_col]))
	draw_polygon(PackedVector2Array([
		pos + Vector2(-14, -13),
		pos + Vector2(-12, -21),
		pos + Vector2(-7, -15)
	]), PackedColorArray([white_col]))
	draw_polygon(PackedVector2Array([
		pos + Vector2(7, -15),
		pos + Vector2(12, -21),
		pos + Vector2(14, -13)
	]), PackedColorArray([white_col]))

	# Head
	_draw_oval(Rect2(pos.x - 18, pos.y - 18, 36, 32), body_col)

	# White Cheek / Muzzle Patches
	draw_polygon(PackedVector2Array([
		pos + Vector2(-15, -4),
		pos + Vector2(-3, -6),
		pos + Vector2(0, 1),
		pos + Vector2(-12, 4)
	]), PackedColorArray([white_col]))
	draw_polygon(PackedVector2Array([
		pos + Vector2(15, -4),
		pos + Vector2(3, -6),
		pos + Vector2(0, 1),
		pos + Vector2(12, 4)
	]), PackedColorArray([white_col]))

	_draw_eyes(pos)
	draw_circle(pos + Vector2(0, -4), 2.2, black_col)
	_draw_whiskers(pos)

	# Paws
	draw_circle(pos + Vector2(-9, 6), 3.2, black_col)
	draw_circle(pos + Vector2(9, 6), 3.2, black_col)

func _draw_eyes(pos: Vector2):
	if current_state == State.WHACKED:
		_draw_x_eye(pos + Vector2(-8, -10))
		_draw_x_eye(pos + Vector2(8, -10))
	else:
		# Large Anime Pupils
		draw_circle(pos + Vector2(-8, -10), 3.8, Color(0.08, 0.08, 0.10))
		draw_circle(pos + Vector2(8, -10), 3.8, Color(0.08, 0.08, 0.10))
		# Primary Large Specular Catchlight
		draw_circle(pos + Vector2(-9.0, -11.5), 1.5, Color.WHITE)
		draw_circle(pos + Vector2(7.0, -11.5), 1.5, Color.WHITE)
		# Secondary Mini Sparkle Catchlight
		draw_circle(pos + Vector2(-6.8, -8.8), 0.8, Color(1.0, 1.0, 1.0, 0.85))
		draw_circle(pos + Vector2(9.2, -8.8), 0.8, Color(1.0, 1.0, 1.0, 0.85))

func _draw_whiskers(pos: Vector2):
	draw_line(pos + Vector2(-4, -4), pos + Vector2(-17, -5), Color(0.35, 0.25, 0.2), 1.0)
	draw_line(pos + Vector2(-4, -2), pos + Vector2(-16, 0), Color(0.35, 0.25, 0.2), 1.0)
	draw_line(pos + Vector2(4, -4), pos + Vector2(17, -5), Color(0.35, 0.25, 0.2), 1.0)
	draw_line(pos + Vector2(4, -2), pos + Vector2(16, 0), Color(0.35, 0.25, 0.2), 1.0)

func _draw_accessories(pos: Vector2):
	if hamster_type == HamsterType.GOLDEN:
		var crown_pts = PackedVector2Array([
			pos + Vector2(-8, -22),
			pos + Vector2(-10, -28),
			pos + Vector2(-4, -24),
			pos + Vector2(0, -29),
			pos + Vector2(4, -24),
			pos + Vector2(10, -28),
			pos + Vector2(8, -22)
		])
		draw_colored_polygon(crown_pts, Color(1.0, 0.85, 0.0))
		draw_circle(pos + Vector2(0, -25), 1.5, Color(0.95, 0.2, 0.2))
	elif hamster_type == HamsterType.BOMB:
		draw_line(pos + Vector2(0, -22), pos + Vector2(4, -28), Color(0.3, 0.3, 0.3), 1.5)
		draw_circle(pos + Vector2(4, -28), 2.5, Color(1.0, 0.3, 0.1))

func _draw_x_eye(p: Vector2):
	var sz = 2.8
	draw_line(p + Vector2(-sz, -sz), p + Vector2(sz, sz), Color(0.1, 0.1, 0.1), 1.8)
	draw_line(p + Vector2(-sz, sz), p + Vector2(sz, -sz), Color(0.1, 0.1, 0.1), 1.8)

func _draw_dizzy_stars(head_pos: Vector2):
	# 3 golden stars orbiting in an ellipse
	var rx = 20.0
	var ry = 7.0
	for i in range(3):
		var a = star_angle + float(i) * (TAU / 3.0)
		var star_pos = head_pos + Vector2(cos(a) * rx, sin(a) * ry)
		_draw_mini_star(star_pos, Color(1.0, 0.95, 0.2))

func _draw_mini_star(p: Vector2, col: Color):
	var s = 3.2
	draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), col, 1.6)
	draw_line(p + Vector2(0, -s), p + Vector2(0, s), col, 1.6)
	draw_circle(p, 1.2, Color.WHITE)
