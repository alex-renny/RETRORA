extends Area2D

signal collected(points: int)

var base_y: float = 0.0
var is_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	if is_collected:
		return
	# Gentle floating bob animation
	position.y = base_y + sin(Time.get_ticks_msec() * 0.006) * 4.0

func _on_body_entered(body: Node2D):
	if is_collected:
		return
	if body.is_in_group("player"):
		is_collected = true
		collected.emit(100)
		# Quick pickup scale pop
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)
