extends Area2D

signal health_changed(new_hp: int)
signal died

const LASER_SCENE = preload("res://scenes/space_defender/Laser.tscn")

var current_jet_id: String = "starfighter"
var move_speed: float = 230.0
var fire_rate: float = 0.18
var max_hp: int = 3
var hp: int = 3

var is_invulnerable: bool = false
var is_active: bool = true
var fire_timer: float = 0.0
var is_firing: bool = true
var move_vec: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("player")
	if sprite:
		sprite.visible = false
	apply_jet(SaveManager.get_equipped("space_jet", "starfighter"))
	reset()

func apply_jet(jet_id: String):
	current_jet_id = jet_id
	match jet_id:
		"interceptor":
			move_speed = 270.0
			fire_rate = 0.20
			max_hp = 3
		"plasma_cruiser":
			move_speed = 200.0
			fire_rate = 0.24
			max_hp = 4
		"phantom_bomber":
			move_speed = 245.0
			fire_rate = 0.12
			max_hp = 3
		"golden_valkyrie":
			move_speed = 265.0
			fire_rate = 0.14
			max_hp = 5
		_: # starfighter
			move_speed = 230.0
			fire_rate = 0.18
			max_hp = 3

	hp = max_hp
	health_changed.emit(hp)
	queue_redraw()

func reset():
	hp = max_hp
	position = Vector2(180, 540)
	is_active = true
	is_invulnerable = false
	modulate = Color.WHITE
	fire_timer = 0.0
	health_changed.emit(hp)
	queue_redraw()

func _process(delta: float):
	if not is_active:
		return

	# 1. Keyboard / Arrow Movement
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0

	if move_vec != Vector2.ZERO:
		dir = move_vec

	position += dir.normalized() * move_speed * delta
	position.x = clamp(position.x, 20.0, 340.0)
	position.y = clamp(position.y, 380.0, 600.0)

	# 2. Weapon Firing
	fire_timer -= delta
	if is_firing and fire_timer <= 0.0:
		fire_timer = fire_rate
		_fire_lasers()

func _fire_lasers():
	match current_jet_id:
		"interceptor":
			# Triple spread shot
			_spawn_laser(position + Vector2(-10, -8), Vector2(-120, -500))
			_spawn_laser(position + Vector2(0, -14), Vector2(0, -540))
			_spawn_laser(position + Vector2(10, -8), Vector2(120, -500))
		"plasma_cruiser":
			# Dual heavy bolts
			_spawn_laser(position + Vector2(-10, -14), Vector2(0, -520))
			_spawn_laser(position + Vector2(10, -14), Vector2(0, -520))
		"phantom_bomber":
			# Rapid quad blasters
			_spawn_laser(position + Vector2(-12, -6), Vector2(0, -550))
			_spawn_laser(position + Vector2(-4, -12), Vector2(0, -550))
			_spawn_laser(position + Vector2(4, -12), Vector2(0, -550))
			_spawn_laser(position + Vector2(12, -6), Vector2(0, -550))
		"golden_valkyrie":
			# High-powered piercing spread
			_spawn_laser(position + Vector2(-8, -12), Vector2(-60, -550))
			_spawn_laser(position + Vector2(0, -16), Vector2(0, -580))
			_spawn_laser(position + Vector2(8, -12), Vector2(60, -550))
		_:
			# Starfighter standard twin lasers
			_spawn_laser(position + Vector2(-8, -12), Vector2(0, -500))
			_spawn_laser(position + Vector2(8, -12), Vector2(0, -500))

func _spawn_laser(spawn_pos: Vector2, vel: Vector2):
	var laser = LASER_SCENE.instantiate()
	get_parent().add_child(laser)
	laser.setup(spawn_pos, vel, "enemy")

func set_move_vector(vec: Vector2):
	move_vec = vec

func set_firing(firing: bool):
	is_firing = firing

func take_damage(amount: int = 1):
	if not is_active or is_invulnerable:
		return

	hp -= amount
	health_changed.emit(hp)

	if hp <= 0:
		is_active = false
		died.emit()
	else:
		_start_invulnerability()

func _start_invulnerability():
	is_invulnerable = true
	var tween = create_tween()
	for i in range(5):
		tween.tween_property(self, "modulate:a", 0.2, 0.1)
		tween.tween_property(self, "modulate:a", 1.0, 0.1)
	tween.tween_callback(func(): is_invulnerable = false)

func _draw():
	match current_jet_id:
		"interceptor":
			_draw_interceptor()
		"plasma_cruiser":
			_draw_plasma_cruiser()
		"phantom_bomber":
			_draw_phantom_bomber()
		"golden_valkyrie":
			_draw_golden_valkyrie()
		_:
			_draw_starfighter()

func _draw_starfighter():
	# Cyan/Blue Starfighter
	draw_polygon(PackedVector2Array([
		Vector2(0, -16),
		Vector2(-14, 12),
		Vector2(-6, 8),
		Vector2(0, 12),
		Vector2(6, 8),
		Vector2(14, 12)
	]), PackedColorArray([Color(0.2, 0.6, 1.0)]))
	# Canopy
	draw_polygon(PackedVector2Array([
		Vector2(0, -10),
		Vector2(-3, 0),
		Vector2(3, 0)
	]), PackedColorArray([Color(0.8, 0.95, 1.0)]))
	# Thruster flames
	draw_line(Vector2(-6, 9), Vector2(-6, 15), Color(1.0, 0.6, 0.1), 2.0)
	draw_line(Vector2(6, 9), Vector2(6, 15), Color(1.0, 0.6, 0.1), 2.0)

func _draw_interceptor():
	# Red/Orange Swift Dart
	draw_polygon(PackedVector2Array([
		Vector2(0, -18),
		Vector2(-16, 8),
		Vector2(-10, 4),
		Vector2(-4, 12),
		Vector2(4, 12),
		Vector2(10, 4),
		Vector2(16, 8)
	]), PackedColorArray([Color(1.0, 0.25, 0.2)]))
	# Swept wing edges
	draw_line(Vector2(-16, 8), Vector2(0, -18), Color(1.0, 0.8, 0.2), 1.5)
	draw_line(Vector2(16, 8), Vector2(0, -18), Color(1.0, 0.8, 0.2), 1.5)
	# Center yellow canopy
	draw_circle(Vector2(0, -3), 3.0, Color(1.0, 0.9, 0.2))

func _draw_plasma_cruiser():
	# Heavy Armored Emerald Cruiser
	draw_rect(Rect2(-12, -8, 24, 18), Color(0.1, 0.7, 0.4))
	draw_polygon(PackedVector2Array([
		Vector2(0, -16),
		Vector2(-12, -8),
		Vector2(12, -8)
	]), PackedColorArray([Color(0.15, 0.85, 0.5)]))
	# Side armor pods
	draw_rect(Rect2(-16, -2, 5, 14), Color(0.08, 0.5, 0.3))
	draw_rect(Rect2(11, -2, 5, 14), Color(0.08, 0.5, 0.3))
	# Core energy glow
	draw_circle(Vector2(0, 1), 4.0, Color(0.3, 1.0, 0.7))

func _draw_phantom_bomber():
	# Sleek Violet Stealth Jet
	draw_polygon(PackedVector2Array([
		Vector2(0, -17),
		Vector2(-18, 10),
		Vector2(-8, 14),
		Vector2(0, 8),
		Vector2(8, 14),
		Vector2(18, 10)
	]), PackedColorArray([Color(0.35, 0.15, 0.55)]))
	# Neon pink wing panels
	draw_line(Vector2(-14, 8), Vector2(0, -12), Color(0.9, 0.2, 0.8), 2.0)
	draw_line(Vector2(14, 8), Vector2(0, -12), Color(0.9, 0.2, 0.8), 2.0)
	# Twin cockpit sensors
	draw_circle(Vector2(-3, -2), 2.0, Color(1.0, 0.2, 0.8))
	draw_circle(Vector2(3, -2), 2.0, Color(1.0, 0.2, 0.8))

func _draw_golden_valkyrie():
	# Celestial Gold God-Ship
	draw_polygon(PackedVector2Array([
		Vector2(0, -20),
		Vector2(-15, -4),
		Vector2(-18, 12),
		Vector2(-6, 8),
		Vector2(0, 14),
		Vector2(6, 8),
		Vector2(18, 12),
		Vector2(15, -4)
	]), PackedColorArray([Color(1.0, 0.82, 0.1)]))
	# Golden wing trims
	draw_line(Vector2(-18, 12), Vector2(0, -20), Color(1.0, 1.0, 0.6), 2.0)
	draw_line(Vector2(18, 12), Vector2(0, -20), Color(1.0, 1.0, 0.6), 2.0)
	# Celestial diamond core
	draw_polygon(PackedVector2Array([
		Vector2(0, -8),
		Vector2(-4, -2),
		Vector2(0, 4),
		Vector2(4, -2)
	]), PackedColorArray([Color(0.2, 0.9, 1.0)]))

