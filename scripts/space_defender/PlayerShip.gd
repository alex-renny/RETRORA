extends Area2D

signal health_changed(new_hp: int)
signal died

const SPEED: float = 230.0
const FIRE_RATE: float = 0.18
const LASER_SCENE = preload("res://scenes/space_defender/Laser.tscn")

var max_hp: int = 3
var hp: int = 3
var is_invulnerable: bool = false
var is_active: bool = true
var fire_timer: float = 0.0
var is_firing: bool = true # Auto-fire enabled by default for smooth mobile play!
var move_vec: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("player")
	reset()

func reset():
	hp = max_hp
	position = Vector2(180, 540)
	is_active = true
	is_invulnerable = false
	modulate = Color.WHITE
	fire_timer = 0.0
	health_changed.emit(hp)

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

	# Combine with Touch move vector
	if move_vec != Vector2.ZERO:
		dir = move_vec

	position += dir.normalized() * SPEED * delta
	position.x = clamp(position.x, 20.0, 340.0)
	position.y = clamp(position.y, 400.0, 600.0)

	# 2. Weapon Firing
	fire_timer -= delta
	if is_firing and fire_timer <= 0.0:
		fire_timer = FIRE_RATE
		_fire_lasers()

func _fire_lasers():
	var laser_left = LASER_SCENE.instantiate()
	var laser_right = LASER_SCENE.instantiate()
	get_parent().add_child(laser_left)
	get_parent().add_child(laser_right)
	laser_left.setup(position + Vector2(-8, -12), Vector2(0, -500), "enemy")
	laser_right.setup(position + Vector2(8, -12), Vector2(0, -500), "enemy")

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
	# Flash effect
	for i in range(5):
		tween.tween_property(self, "modulate:a", 0.2, 0.1)
		tween.tween_property(self, "modulate:a", 1.0, 0.1)
	tween.tween_callback(func(): is_invulnerable = false)
