extends Node2D

const THEMES = {
	"city": {
		"name": "City",
		"road": Color("242428"),
		"stripes": Color("e0e0e0"),
		"shoulder": Color("3d3d45"),
		"edge": Color("555560")
	},
	"cyber_neon": {
		"name": "Cyber Neon",
		"road": Color("0a0e1c"),
		"stripes": Color("00f0ff"),
		"shoulder": Color("190e2e"),
		"edge": Color("f000ff")
	},
	"desert": {
		"name": "Desert Highway",
		"road": Color("3b2f23"),
		"stripes": Color("ffcc44"),
		"shoulder": Color("8b5a2b"),
		"edge": Color("d28c46")
	},
	"sunset_coast": {
		"name": "Sunset Coast",
		"road": Color("1c142b"),
		"stripes": Color("ff5588"),
		"shoulder": Color("421a4f"),
		"edge": Color("ffaa33")
	},
	"lava_gorge": {
		"name": "Lava Gorge",
		"road": Color("220a0a"),
		"stripes": Color("ff4400"),
		"shoulder": Color("551105"),
		"edge": Color("ffaa00")
	}
}

var current_road_id: String = "city"
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

func set_road_by_id(id: String):
	if THEMES.has(id):
		current_road_id = id
	queue_redraw()

func set_theme(idx: int):
	var keys = THEMES.keys()
	if idx >= 0 and idx < keys.size():
		current_road_id = keys[idx]
	queue_redraw()

func set_speed(speed: float):
	scroll_speed = speed

func _draw():
	var theme = THEMES.get(current_road_id, THEMES["city"])

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
