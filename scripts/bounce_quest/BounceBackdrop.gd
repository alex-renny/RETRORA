extends Node2D

# A hand-drawn, animated backdrop inspired by cheerful 2D platformers: blue sky,
# drifting clouds, rounded bushes, and small mushroom silhouettes.
var time_alive := 0.0

func _process(delta: float) -> void:
	time_alive += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-400, -300, 2600, 1000), Color("69c9f2"))
	_draw_cloud(Vector2(120 + fposmod(time_alive * 8.0, 760.0), 80), 1.0)
	_draw_cloud(Vector2(680 - fposmod(time_alive * 5.0, 900.0), 180), 0.72)
	_draw_cloud(Vector2(1120 + sin(time_alive * 0.3) * 30.0, 55), 0.56)

	# Soft distant hills keep the lower world from feeling empty.
	for x in range(-200, 1900, 170):
		var hill_height := 55.0 + float((x / 170) % 3) * 16.0
		draw_circle(Vector2(x, 610), hill_height, Color("4aab82"))
		draw_circle(Vector2(x + 54, 618), hill_height * 0.82, Color("39976e"))

	for x in range(40, 1800, 250):
		_draw_bush(Vector2(x, 500 + sin(float(x) * 0.1) * 12.0))

func _draw_cloud(at: Vector2, scale_factor: float) -> void:
	var cloud := Color(1.0, 1.0, 1.0, 0.88)
	draw_circle(at, 22 * scale_factor, cloud)
	draw_circle(at + Vector2(25, -9) * scale_factor, 29 * scale_factor, cloud)
	draw_circle(at + Vector2(57, 2) * scale_factor, 20 * scale_factor, cloud)
	draw_rect(Rect2(at + Vector2(-18, 2) * scale_factor, Vector2(95, 22) * scale_factor), cloud)

func _draw_bush(at: Vector2) -> void:
	var dark := Color("14723e")
	var light := Color("43d94b")
	draw_circle(at + Vector2(0, 16), 27, dark)
	draw_circle(at + Vector2(27, 5), 35, dark)
	draw_circle(at + Vector2(55, 18), 25, dark)
	draw_circle(at + Vector2(4, 10), 19, light)
	draw_circle(at + Vector2(29, -1), 25, light)
	draw_circle(at + Vector2(54, 13), 18, light)
	# Tiny mushroom cap for the playful foreground language of the reference.
	draw_rect(Rect2(at + Vector2(72, 25), Vector2(5, 15)), Color("fff0cf"))
	draw_circle(at + Vector2(74, 23), 10, Color("f49555"))
