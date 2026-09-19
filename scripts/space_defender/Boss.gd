extends Area2D

signal health_changed(current: int, total: int)
signal boss_defeated

var max_hp: int = 45
var hp: int = 45
var strafe_speed: float = 65.0
var move_dir: float = 1.0
var state_timer: float = 0.0
var attack_timer: float = 1.5
var is_active: bool = false
var is_enraged: bool = false
var player_ref: Node2D = null

const LASER_SCENE = preload("res://scenes/space_defender/Laser.tscn")
var boss_laser_tex = preload("res://assets/space_defender/laser_boss.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("enemy")
	add_to_group("boss")
	position = Vector2(180, -70)
	hp = max_hp

func start_battle(player: Node2D):
	player_ref = player
	hp = max_hp
	health_changed.emit(hp, max_hp)

	# Dramatic entrance tween
	var tween = create_tween()
	tween.tween_property(self, "position:y", 95.0, 2.5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): is_active = true)

func _process(delta: float):
	if not is_active:
		return

	# Strafe left and right
	position.x += move_dir * strafe_speed * delta
	if position.x <= 55.0:
		move_dir = 1.0
	elif position.x >= 305.0:
		move_dir = -1.0

	# Attack pattern timer
	attack_timer -= delta
	if attack_timer <= 0.0:
		if is_enraged:
			attack_timer = 1.2
			_fire_enraged_spread()
		else:
			attack_timer = 1.8
			_fire_twin_cannons()

func _fire_twin_cannons():
	_spawn_boss_bullet(position + Vector2(-20, 24), Vector2(0, 260))
	_spawn_boss_bullet(position + Vector2(20, 24), Vector2(0, 260))

func _fire_enraged_spread():
	# 5-way spread
	var angles = [-40.0, -20.0, 0.0, 20.0, 40.0]
	for a in angles:
		var rad = deg_to_rad(a + 90.0) # Downward fan
		var vel = Vector2(cos(rad), sin(rad)) * 240.0
		_spawn_boss_bullet(position + Vector2(0, 24), vel)

func _spawn_boss_bullet(pos: Vector2, vel: Vector2):
	var laser = LASER_SCENE.instantiate()
	get_parent().add_child(laser)
	laser.get_node("Sprite2D").texture = boss_laser_tex
	laser.setup(pos, vel, "player", 1)

func take_damage(amount: int = 1):
	if not is_active:
		return

	hp -= amount
	health_changed.emit(hp, max_hp)

	# Check Enrage transition
	if not is_enraged and hp <= max_hp / 2:
		is_enraged = true
		strafe_speed = 115.0
		sprite.modulate = Color(1.4, 0.6, 1.2, 1.0) # Neon purple glow

	# Hit flash
	var orig_mod = sprite.modulate
	sprite.modulate = Color(2.0, 0.2, 0.2, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", orig_mod, 0.08)

	if hp <= 0:
		_die()

func _die():
	is_active = false
	boss_defeated.emit()
	var tween = create_tween()
	# Dramatic disintegration
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.5)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
