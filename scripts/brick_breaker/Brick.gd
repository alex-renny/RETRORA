extends StaticBody2D

signal destroyed(pts: int, b_type: int, pos: Vector2)

enum Type { NORMAL, STRONG, BONUS, EXPLOSIVE }

var brick_type: Type = Type.NORMAL
var hp: int = 1
var is_destroyed: bool = false

var tex_normal = preload("res://assets/brick_breaker/brick_normal.png")
var tex_strong = preload("res://assets/brick_breaker/brick_strong.png")
var tex_strong_cracked = preload("res://assets/brick_breaker/brick_strong_cracked.png")
var tex_bonus = preload("res://assets/brick_breaker/brick_bonus.png")
var tex_explosive = preload("res://assets/brick_breaker/brick_explosive.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("bricks")

func setup(t: Type):
	brick_type = t
	match brick_type:
		Type.NORMAL:
			hp = 1
			sprite.texture = tex_normal
		Type.STRONG:
			hp = 2
			sprite.texture = tex_strong
		Type.BONUS:
			hp = 1
			sprite.texture = tex_bonus
		Type.EXPLOSIVE:
			hp = 1
			sprite.texture = tex_explosive

func hit():
	if is_destroyed:
		return

	hp -= 1
	if hp <= 0:
		is_destroyed = true
		var pts = 100
		match brick_type:
			Type.NORMAL: pts = 100
			Type.STRONG: pts = 200
			Type.BONUS: pts = 300
			Type.EXPLOSIVE: pts = 250

		destroyed.emit(pts, brick_type, global_position)

		# If explosive, trigger neighboring bricks!
		if brick_type == Type.EXPLOSIVE:
			_explode_neighbors()

		# Quick destruction scale pop
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.08)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.08)
		tween.tween_callback(queue_free)
	else:
		# Strong brick cracked state
		sprite.texture = tex_strong_cracked

func _explode_neighbors():
	for b in get_tree().get_nodes_in_group("bricks"):
		if is_instance_valid(b) and b != self:
			if global_position.distance_to(b.global_position) <= 52.0:
				b.hit()
