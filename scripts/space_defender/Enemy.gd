extends Area2D

signal killed(points: int)

enum Type { BASIC, FAST, TANK, SHOOTER }

var enemy_type: Type = Type.BASIC
var hp: int = 1
var max_hp: int = 1
var points: int = 100
var speed: float = 120.0
var fire_timer: float = 2.0
var player_ref: Node2D = null

# Movement tracking
var time_alive: float = 0.0
var initial_x: float = 0.0
var move_dir_x: float = 1.0

const LASER_SCENE = preload("res://scenes/space_defender/Laser.tscn")
var enemy_laser_tex = preload("res://assets/space_defender/laser_enemy.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("enemy")
	initial_x = position.x
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup(t: Type, spawn_pos: Vector2, player: Node2D):
	enemy_type = t
	position = spawn_pos
	initial_x = spawn_pos.x
	player_ref = player

	match enemy_type:
		Type.BASIC:
			hp = 1
			points = 100
			speed = 130.0
			fire_timer = randf_range(2.0, 3.8)
			sprite.texture = preload("res://assets/space_defender/enemy_basic.png")
		Type.FAST:
			hp = 1
			points = 150
			speed = 210.0
			fire_timer = 999.0 # Darts dive instead of shooting
			move_dir_x = 1.0 if randf() > 0.5 else -1.0
			sprite.texture = preload("res://assets/space_defender/enemy_fast.png")
		Type.TANK:
			hp = 5
			points = 300
			speed = 65.0
			fire_timer = 2.5
			sprite.texture = preload("res://assets/space_defender/enemy_tank.png")
		Type.SHOOTER:
			hp = 2
			points = 200
			speed = 100.0
			fire_timer = 1.8
			sprite.texture = preload("res://assets/space_defender/enemy_shooter.png")

	max_hp = hp

func _process(delta: float):
	time_alive += delta

	# Behavior based on type
	match enemy_type:
		Type.BASIC:
			position.y += speed * delta
			position.x = initial_x + sin(time_alive * 3.2) * 40.0
			_tick_fire(delta, false)

		Type.FAST:
			position.y += speed * delta
			position.x += move_dir_x * 125.0 * delta
			if position.x <= 20.0:
				move_dir_x = 1.0
			elif position.x >= 340.0:
				move_dir_x = -1.0

		Type.TANK:
			position.y += speed * delta
			_tick_fire(delta, true)

		Type.SHOOTER:
			if position.y < 140.0:
				position.y += speed * delta
			else:
				# Strafe left/right at mid screen
				position.x += move_dir_x * 90.0 * delta
				if position.x <= 30.0:
					move_dir_x = 1.0
				elif position.x >= 330.0:
					move_dir_x = -1.0
				_tick_aimed_fire(delta)

	# Continuous assault: loop back around from top if player dodges past them
	if position.y > 660.0:
		position.y = -35.0
		position.x = randf_range(35.0, 325.0)
		initial_x = position.x

func _tick_fire(delta: float, is_burst: bool):
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = randf_range(2.0, 3.5)
		if is_burst:
			# 3 bullet fan
			_spawn_enemy_laser(Vector2(0, 240))
			_spawn_enemy_laser(Vector2(-60, 230))
			_spawn_enemy_laser(Vector2(60, 230))
		else:
			_spawn_enemy_laser(Vector2(0, 240))

func _tick_aimed_fire(delta: float):
	fire_timer -= delta
	if fire_timer <= 0.0 and player_ref and is_instance_valid(player_ref):
		fire_timer = 2.0
		var aim_dir = (player_ref.position - position).normalized()
		_spawn_enemy_laser(aim_dir * 240.0)

func _spawn_enemy_laser(vel: Vector2):
	var laser = LASER_SCENE.instantiate()
	get_parent().add_child(laser)
	laser.get_node("Sprite2D").texture = enemy_laser_tex
	laser.setup(position + Vector2(0, 12), vel, "player")

func take_damage(amount: int = 1):
	hp -= amount
	# Flash red
	modulate = Color(2.0, 0.3, 0.3, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.08)

	if hp <= 0:
		killed.emit(points)
		# Quick explosion pop
		var pop_tween = create_tween()
		pop_tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.1)
		pop_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
		pop_tween.tween_callback(queue_free)

func _on_area_entered(area: Area2D):
	if area.is_in_group("player") and area.has_method("take_damage"):
		area.take_damage(1)
		take_damage(99)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
		take_damage(99)
