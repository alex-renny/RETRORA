class_name GameLibraryCard
extends Control

signal play_requested(game_id: String)
signal customize_requested(game_id: String)

var game_id := ""
var game_title := ""
var best_score := 0
var is_recent := false
var palette: Dictionary = {}
var accent := Color("4dd8ff")
var accent_two := Color("7467ff")

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(148, 232)
	tooltip_text = "Play %s" % game_title

func setup(id: String, info: Dictionary, score: int, recent: bool, pal: Dictionary) -> void:
	game_id = id
	game_title = info.get("title", id)
	best_score = score
	is_recent = recent
	_set_cover_colours()
	refresh_theme(pal)

func refresh_theme(pal: Dictionary) -> void:
	palette = pal
	queue_redraw()

func _set_cover_colours() -> void:
	match game_id:
		"snake": accent = Color("75e35a"); accent_two = Color("129c73")
		"sky_hopper": accent = Color("60cdfb"); accent_two = Color("8068f1")
		"bounce_quest": accent = Color("ff5c92"); accent_two = Color("8a5dff")
		"brick_breaker": accent = Color("ffb238"); accent_two = Color("fb4e72")
		"retro_racer": accent = Color("ff4a57"); accent_two = Color("ff9d36")
		"space_defender": accent = Color("6feeff"); accent_two = Color("5374ed")
		"hamster_game": accent = Color("ffc867"); accent_two = Color("df7251")
		"block_fill": accent = Color("bd5cff"); accent_two = Color("2ee9ee")

func _draw() -> void:
	var cover_h := size.y - 45.0
	var cover := Rect2(Vector2.ZERO, Vector2(size.x, cover_h))
	var card_bg: Color = palette.get("card_bg", Color("111827"))
	var text_primary: Color = palette.get("text_primary", Color.WHITE)
	var text_secondary: Color = palette.get("text_secondary", Color("9aa5b5"))
	draw_style_box(_rounded_box(accent.darkened(0.73), accent.darkened(0.22)), cover)
	draw_circle(Vector2(size.x * 0.80, cover_h * 0.18), cover_h * 0.23, accent_two.darkened(0.10))
	for n in 5:
		var y := cover_h * (0.20 + n * 0.14)
		draw_line(Vector2(0, y), Vector2(size.x, y - size.x * 0.32), Color(accent.lightened(0.18), 0.25), 1.0)
	_draw_game_mark(cover_h)

	if is_recent:
		var new_box := Rect2(8, 8, 40, 20)
		draw_style_box(_solid_box(Color("f7f1c5"), Color("f7f1c5"), 5), new_box)
		draw_string(ThemeDB.fallback_font, Vector2(14, 23), "NEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("1b2432"))

	var menu_box := Rect2(size.x - 31, 8, 23, 20)
	draw_style_box(_solid_box(Color(0.03, 0.05, 0.10, 0.48), Color.TRANSPARENT, 5), menu_box)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 25, 23), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	var name_rect := Rect2(0, cover_h, size.x, 45)
	draw_style_box(_solid_box(card_bg, Color(palette.get("card_border", accent), 0.9), 8), name_rect)
	draw_string(ThemeDB.fallback_font, Vector2(9, cover_h + 18), game_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 18, 12, text_primary)
	draw_string(ThemeDB.fallback_font, Vector2(9, cover_h + 34), "BEST  %d" % best_score, HORIZONTAL_ALIGNMENT_LEFT, size.x - 18, 10, text_secondary)

func _draw_game_mark(cover_h: float) -> void:
	var center := Vector2(size.x * 0.50, cover_h * 0.58)
	match game_id:
		"snake":
			for n in 5:
				draw_circle(center + Vector2((n - 2) * 15, sin(n * 1.4) * 11), 12, accent)
			draw_circle(center + Vector2(35, -7), 2, Color.WHITE)
		"sky_hopper":
			draw_circle(center, 27, accent)
			draw_colored_polygon(PackedVector2Array([center + Vector2(18, 1), center + Vector2(50, 10), center + Vector2(18, 18)]), Color("ffdb4e"))
			draw_circle(center + Vector2(9, -8), 4, Color.WHITE)
		"bounce_quest", "brick_breaker":
			draw_circle(center, 34, accent)
			draw_arc(center, 22, 0.35, 3.4, 24, Color(Color.WHITE, 0.55), 3)
		"retro_racer":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-43, 26), center + Vector2(-24, -28), center + Vector2(24, -28), center + Vector2(43, 26)]), accent)
			draw_circle(center + Vector2(-24, 24), 9, Color("172031"))
			draw_circle(center + Vector2(24, 24), 9, Color("172031"))
		"space_defender":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -43), center + Vector2(-34, 35), center + Vector2(0, 22), center + Vector2(34, 35)]), accent)
			draw_circle(center + Vector2(0, 3), 10, Color.WHITE)
		"hamster_game":
			draw_circle(center, 34, accent)
			draw_circle(center + Vector2(-20, -29), 14, accent)
			draw_circle(center + Vector2(20, -29), 14, accent)
			draw_circle(center + Vector2(-12, -2), 4, Color("39263a"))
			draw_circle(center + Vector2(12, -2), 4, Color("39263a"))
		"block_fill":
			for x in 3:
				for y in 3:
					draw_rect(Rect2(center + Vector2((x - 1) * 24, (y - 1) * 24), Vector2(18, 18)), accent if (x + y) % 2 == 0 else accent_two)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.position.x >= size.x - 38.0 and event.position.y <= 38.0:
			customize_requested.emit(game_id)
		else:
			play_requested.emit(game_id)

func _rounded_box(bg: Color, border: Color) -> StyleBoxFlat:
	return _solid_box(bg, border, 10)

func _solid_box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box
