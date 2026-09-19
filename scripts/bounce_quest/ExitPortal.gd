extends Area2D

signal reached_goal

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	# Pulsating glow
	modulate.a = 0.8 + sin(Time.get_ticks_msec() * 0.005) * 0.2

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		reached_goal.emit()
