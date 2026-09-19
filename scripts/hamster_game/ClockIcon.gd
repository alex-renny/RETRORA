extends Control

func _draw():
	var center = Vector2(14, 14)
	var pink = Color(0.96, 0.42, 0.65)
	var white = Color.WHITE
	var dark = Color(0.2, 0.2, 0.2)

	# Twin bells
	draw_circle(center + Vector2(-9, -9), 4.5, pink)
	draw_circle(center + Vector2(9, -9), 4.5, pink)

	# Feet
	draw_line(center + Vector2(-7, 9), center + Vector2(-10, 13), pink, 2.0)
	draw_line(center + Vector2(7, 9), center + Vector2(10, 13), pink, 2.0)

	# Main clock body
	draw_circle(center, 12.0, pink)
	draw_circle(center, 9.5, white)

	# Clock hands (10 and 2)
	draw_line(center, center + Vector2(-4, -5), dark, 1.5)
	draw_line(center, center + Vector2(5, -3), dark, 1.5)
	draw_circle(center, 1.5, dark)
