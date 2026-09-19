extends Area2D

var velocity: Vector2 = Vector2(0, -480)
var target_group: String = "enemy"
var damage: int = 1

func setup(pos: Vector2, vel: Vector2, group: String, dmg: int = 1):
	position = pos
	velocity = vel
	target_group = group
	damage = dmg

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	position += velocity * delta
	if position.y < -30.0 or position.y > 670.0 or position.x < -30.0 or position.x > 390.0:
		queue_free()

func _on_area_entered(area: Area2D):
	if area.is_in_group(target_group) and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group(target_group) and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
