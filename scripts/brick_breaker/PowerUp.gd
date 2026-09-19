extends Area2D

signal collected(type: int)

enum Type { WIDE, MULTI, SLOW, LIFE }

var power_type: Type = Type.WIDE
var fall_speed: float = 120.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)

func setup(t: Type, pos: Vector2):
	power_type = t
	position = pos
	match power_type:
		Type.WIDE:
			sprite.texture = preload("res://assets/brick_breaker/powerup_wide.png")
		Type.MULTI:
			sprite.texture = preload("res://assets/brick_breaker/powerup_multi.png")
		Type.SLOW:
			sprite.texture = preload("res://assets/brick_breaker/powerup_slow.png")
		Type.LIFE:
			sprite.texture = preload("res://assets/brick_breaker/powerup_life.png")

func _process(delta: float):
	position.y += fall_speed * delta
	if position.y > 650.0:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.has_method("set_wide"): # It's the paddle!
		collected.emit(power_type)
		queue_free()
