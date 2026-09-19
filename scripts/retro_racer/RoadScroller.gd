extends Node2D

const THEMES = [
	{
		"name": "City",
		"road": Color("242428"),
		"stripes": Color("e0e0e0"),
		"shoulder": Color("3d3d45"),
		"edge": Color("555560")
	},
	{
		"name": "Night Road",
		"road": Color("0e121e"),
		"stripes": Color("00f0ff"),
		"shoulder": Color("150d2a"),
		"edge": Color("2a1a4a")
	},
	{
		"name": "Desert Highway",
		"road": Color("3b2f2f"),
		"stripes": Color("ffe082"),
		"shoulder": Color("c28b55"),
		"edge": Color("8c5828")
	}
]

var current_theme_idx: int = 0
var scroll_offset: float = 0.0
var scroll_speed: float = 200.0

const ROAD_LEFT: float = 70.0
const ROAD_RIGHT: float = 290.0
const ROAD_WIDTH: float = 220.0
const STRIPE_LENGTH: float = 32.0
const STRIPE_GAP: float = 28.0
const TOTAL_STRIPE_CYCLE: float = 60.0

func _process(delta: float):
	scroll_offset = fmod(scroll_offset + scroll_speed * delta, TOTAL_STRIPE_CYCLE)
	queue_redraw()

func set_theme(idx: int):
	current_theme_idx = clamp(idx, 0, THEMES.size() - 1)
	queue_redraw()

func set_speed(speed: float):
	scroll_speed = speed

func _draw():
	var theme = THEMES[current_theme_idx]

	# 1. Draw Shoulders
	draw_rect(Rect2(0, 0, ROAD_LEFT, 640), theme["shoulder"])
	draw_rect(Rect2(ROAD_RIGHT, 0, 70, 640), theme["shoulder"])

	# 2. Draw Road Surface
	draw_rect(Rect2(ROAD_LEFT, 0, ROAD_WIDTH, 640), theme["road"])

	# 3. Draw Road Outer Edges
	draw_line(Vector2(ROAD_LEFT, 0), Vector2(ROAD_LEFT, 640), theme["edge"], 3.0)
	draw_line(Vector2(ROAD_RIGHT, 0), Vector2(ROAD_RIGHT, 640), theme["edge"], 3.0)

	# 4. Draw Dashed Lane Dividers
	var lane_1_x = 143.0
	var lane_2_x = 217.0
	var y = scroll_offset - TOTAL_STRIPE_CYCLE

	while y < 640.0:
		draw_rect(Rect2(lane_1_x - 2, y, 4, STRIPE_LENGTH), theme["stripes"])
		draw_rect(Rect2(lane_2_x - 2, y, 4, STRIPE_LENGTH), theme["stripes"])
		y += TOTAL_STRIPE_CYCLE
