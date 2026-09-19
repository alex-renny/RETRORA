extends Control

# ItemPreview renders a crisp 50x50 retro pixel preview for all skins, vehicles,
# arenas, birds, jets, balls, and animals in RETRORA.

var category_key: String = ""
var item_id: String = ""
var is_unlocked: bool = false
var is_equipped: bool = false

func setup(cat: String, id: String, unlocked: bool, equipped: bool = false):
	category_key = cat
	item_id = id
	is_unlocked = unlocked
	is_equipped = equipped
	custom_minimum_size = Vector2(50, 50)
	queue_redraw()

func _draw():
	var w = size.x
	var h = size.y
	var center = Vector2(w * 0.5, h * 0.5)

	# 1. Background tile
	var bg_col = Color(0.07, 0.09, 0.13)
	var border_col = Color(0.2, 0.3, 0.42)
	if is_equipped:
		border_col = Color(0.25, 0.95, 0.5)
	elif not is_unlocked:
		border_col = Color(0.4, 0.3, 0.18)

	draw_rect(Rect2(1, 1, w - 2, h - 2), bg_col)
	draw_rect(Rect2(1, 1, w - 2, h - 2), border_col, false, 1.5)

	# 2. Draw Item Graphics
	match category_key:
		"snake_skin":
			_draw_snake_skin(center)
		"snake_arena":
			_draw_arena_thumb(center, item_id)
		"racer_vehicle":
			_draw_racer_vehicle(center)
		"racer_road":
			_draw_road_thumb(center, item_id)
		"hopper_bird":
			_draw_hopper_bird(center)
		"bounce_ball":
			_draw_bounce_ball(center)
		"space_jet":
			_draw_space_jet(center)
		"brick_paddle":
			_draw_brick_paddle(center)
		"brick_ball":
			_draw_brick_ball(center)
		"brick_arena":
			_draw_brick_arena_thumb(center, item_id)
		"hamster_animal":
			_draw_hamster_animal(center)
		"bounce_ground":
			_draw_bounce_ground_thumb(center, item_id)
		_:
			draw_circle(center, 10.0, Color.WHITE)

	# 3. Locked Overlay: dark shade + padlock badge
	if not is_unlocked:
		draw_rect(Rect2(1, 1, w - 2, h - 2), Color(0.03, 0.04, 0.06, 0.72))
		_draw_lock_icon(center)

func _draw_lock_icon(c: Vector2):
	# Golden padlock in center of preview
	var shackle_col = Color(1.0, 0.88, 0.25)
	var body_col = Color(0.95, 0.72, 0.1)

	# Shackle
	draw_arc(c + Vector2(0, -4), 5.5, PI, TAU, 14, shackle_col, 2.0)
	# Lock body
	draw_rect(Rect2(c.x - 7, c.y - 3, 14, 11), body_col)
	draw_rect(Rect2(c.x - 7, c.y - 3, 14, 11), Color(0.7, 0.5, 0.05), false, 1.0)
	# Keyhole
	draw_circle(c + Vector2(0, 1), 1.6, Color(0.12, 0.12, 0.12))
	draw_line(c + Vector2(0, 1), c + Vector2(0, 5), Color(0.12, 0.12, 0.12), 1.5)

# --- Category Drawers ---

func _draw_snake_skin(c: Vector2):
	var head_col = Color(0.4, 0.9, 0.3)
	var b1_col = Color(0.25, 0.75, 0.25)
	var b2_col = Color(0.2, 0.65, 0.2)
	var eye_col = Color(0.05, 0.1, 0.05)

	match item_id:
		"neon_viper":
			head_col = Color(0.0, 1.0, 0.9)
			b1_col = Color(0.0, 0.7, 1.0)
			b2_col = Color(0.85, 0.1, 1.0)
			eye_col = Color.WHITE
		"desert_cobra":
			head_col = Color(1.0, 0.75, 0.2)
			b1_col = Color(0.85, 0.55, 0.15)
			b2_col = Color(0.7, 0.45, 0.1)
			eye_col = Color(0.9, 0.1, 0.1)
		"cyber_dragon":
			head_col = Color(1.0, 0.2, 0.3)
			b1_col = Color(0.9, 0.1, 0.15)
			b2_col = Color(1.0, 0.7, 0.1)
			eye_col = Color(0.2, 1.0, 0.8)
		"shadow_wyrm":
			head_col = Color(0.65, 0.3, 0.95)
			b1_col = Color(0.3, 0.12, 0.45)
			b2_col = Color(0.18, 0.08, 0.3)
			eye_col = Color(0.9, 0.2, 0.9)

	# Draw 3-segment snake with head
	draw_rect(Rect2(c.x - 5, c.y - 14, 10, 10), head_col)
	draw_rect(Rect2(c.x - 3, c.y - 12, 2, 2), eye_col)
	draw_rect(Rect2(c.x + 1, c.y - 12, 2, 2), eye_col)
	draw_rect(Rect2(c.x - 5, c.y - 2, 10, 8), b1_col)
	draw_rect(Rect2(c.x - 5, c.y + 8, 10, 8), b2_col)

func _draw_arena_thumb(c: Vector2, id: String):
	var bg = Color(0.08, 0.12, 0.08)
	var border = Color(0.3, 0.6, 0.3)
	var grid = Color(0.14, 0.2, 0.14)

	match id:
		"synthwave_grid":
			bg = Color(0.07, 0.04, 0.13)
			border = Color(0.95, 0.2, 0.85)
			grid = Color(0.25, 0.12, 0.4)
		"desert_dunes":
			bg = Color(0.18, 0.13, 0.07)
			border = Color(0.9, 0.65, 0.2)
			grid = Color(0.3, 0.22, 0.12)
		"frozen_tundra":
			bg = Color(0.05, 0.1, 0.16)
			border = Color(0.4, 0.85, 1.0)
			grid = Color(0.12, 0.22, 0.32)
		"volcanic_abyss":
			bg = Color(0.13, 0.03, 0.03)
			border = Color(1.0, 0.35, 0.1)
			grid = Color(0.28, 0.08, 0.06)

	draw_rect(Rect2(c.x - 17, c.y - 17, 34, 34), bg)
	draw_line(Vector2(c.x - 17, c.y), Vector2(c.x + 17, c.y), grid, 1.0)
	draw_line(Vector2(c.x, c.y - 17), Vector2(c.x, c.y + 17), grid, 1.0)
	draw_rect(Rect2(c.x - 17, c.y - 17, 34, 34), border, false, 1.5)
	# Little food dot
	draw_rect(Rect2(c.x + 4, c.y - 8, 4, 4), Color(0.95, 0.2, 0.2))

func _draw_racer_vehicle(c: Vector2):
	match item_id:
		"superbike":
			# Front/Rear tires
			draw_rect(Rect2(c.x - 2, c.y - 14, 4, 7), Color(0.12, 0.12, 0.12))
			draw_rect(Rect2(c.x - 2, c.y + 7, 4, 7), Color(0.12, 0.12, 0.12))
			draw_rect(Rect2(c.x - 3, c.y - 8, 6, 16), Color(0.0, 0.9, 0.6))
			draw_circle(Vector2(c.x, c.y), 3.5, Color(1.0, 0.85, 0.2))
		"muscle_cruiser":
			draw_rect(Rect2(c.x - 8, c.y - 15, 16, 30), Color(0.25, 0.1, 0.45))
			draw_line(Vector2(c.x - 2, c.y - 15), Vector2(c.x - 2, c.y + 15), Color(0.85, 0.85, 0.9), 1.0)
			draw_line(Vector2(c.x + 2, c.y - 15), Vector2(c.x + 2, c.y + 15), Color(0.85, 0.85, 0.9), 1.0)
			draw_rect(Rect2(c.x - 2, c.y - 10, 4, 4), Color.WHITE) # Blower
		"turbo_bus":
			draw_rect(Rect2(c.x - 8, c.y - 18, 16, 36), Color(0.95, 0.65, 0.08))
			draw_rect(Rect2(c.x - 6, c.y - 15, 12, 5), Color(0.2, 0.7, 0.9))
			draw_rect(Rect2(c.x - 6, c.y - 6, 4, 4), Color(0.2, 0.7, 0.9))
			draw_rect(Rect2(c.x + 2, c.y - 6, 4, 4), Color(0.2, 0.7, 0.9))
			draw_rect(Rect2(c.x - 6, c.y + 3, 4, 4), Color(0.2, 0.7, 0.9))
			draw_rect(Rect2(c.x + 2, c.y + 3, 4, 4), Color(0.2, 0.7, 0.9))
		"golden_f1":
			draw_rect(Rect2(c.x - 11, c.y - 14, 22, 3), Color(0.9, 0.75, 0.1)) # Front wing
			draw_rect(Rect2(c.x - 4, c.y - 12, 8, 22), Color(1.0, 0.84, 0.0))
			draw_circle(c, 2.5, Color(0.9, 0.1, 0.2)) # Helmet
			draw_rect(Rect2(c.x - 12, c.y + 10, 24, 3), Color(0.85, 0.65, 0.05)) # Rear wing
		_: # red_racer
			draw_rect(Rect2(c.x - 7, c.y - 14, 14, 28), Color(0.85, 0.15, 0.15))
			draw_rect(Rect2(c.x - 1, c.y - 14, 2, 28), Color.WHITE) # Stripe
			draw_rect(Rect2(c.x - 5, c.y - 4, 10, 8), Color(0.1, 0.15, 0.25)) # Window

func _draw_road_thumb(c: Vector2, id: String):
	var road_col = Color("242428")
	var stripe_col = Color("e0e0e0")
	var shoulder_col = Color("3d3d45")

	match id:
		"cyber_neon":
			road_col = Color("0a0e1c")
			stripe_col = Color("00f0ff")
			shoulder_col = Color("190e2e")
		"desert":
			road_col = Color("3b2f23")
			stripe_col = Color("ffcc44")
			shoulder_col = Color("8b5a2b")
		"sunset_coast":
			road_col = Color("1c142b")
			stripe_col = Color("ff5588")
			shoulder_col = Color("421a4f")
		"lava_gorge":
			road_col = Color("220a0a")
			stripe_col = Color("ff4400")
			shoulder_col = Color("551105")

	draw_rect(Rect2(c.x - 18, c.y - 18, 36, 36), shoulder_col)
	draw_rect(Rect2(c.x - 11, c.y - 18, 22, 36), road_col)
	# Dashed line
	draw_line(Vector2(c.x, c.y - 14), Vector2(c.x, c.y - 4), stripe_col, 2.0)
	draw_line(Vector2(c.x, c.y + 4), Vector2(c.x, c.y + 14), stripe_col, 2.0)

func _draw_hopper_bird(c: Vector2):
	var body_col = Color(1.0, 0.85, 0.1)
	var wing_col = Color(0.9, 0.7, 0.05)
	var beak_col = Color(1.0, 0.45, 0.1)

	match item_id:
		"blue_falcon":
			body_col = Color(0.15, 0.45, 0.95)
			wing_col = Color(0.08, 0.25, 0.65)
			beak_col = Color(1.0, 0.8, 0.1)
		"cyber_drone":
			draw_rect(Rect2(c.x - 8, c.y - 6, 16, 12), Color(0.2, 0.25, 0.35))
			draw_rect(Rect2(c.x + 2, c.y - 2, 6, 4), Color(0.0, 1.0, 0.9))
			draw_circle(Vector2(c.x - 2, c.y), 2.0, Color.RED)
			return
		"pixel_phoenix":
			body_col = Color(1.0, 0.2, 0.1)
			wing_col = Color(1.0, 0.8, 0.0)
			beak_col = Color(1.0, 0.9, 0.2)
		"midnight_bat":
			body_col = Color(0.22, 0.15, 0.3)
			wing_col = Color(0.3, 0.18, 0.4)
			beak_col = Color(1.0, 0.15, 0.3) # ruby eye

	draw_circle(c, 8.0, body_col)
	draw_circle(c + Vector2(2, 2), 4.5, Color(body_col.r * 1.1, body_col.g * 1.1, body_col.b * 1.1))
	draw_polygon(PackedVector2Array([c + Vector2(-5, -2), c + Vector2(2, -5), c + Vector2(0, 3)]), PackedColorArray([wing_col]))
	draw_circle(c + Vector2(4, -2), 2.5, Color.WHITE)
	draw_circle(c + Vector2(5, -2), 1.2, Color.BLACK)
	draw_polygon(PackedVector2Array([c + Vector2(7, -1), c + Vector2(12, 0), c + Vector2(7, 2)]), PackedColorArray([beak_col]))

func _draw_bounce_ball(c: Vector2):
	var col = Color(0.9, 0.15, 0.15)
	if item_id == "neon_pulse":
		col = Color(0.1, 1.0, 0.95)
	elif item_id == "golden_orb":
		col = Color(1.0, 0.85, 0.15)

	draw_circle(c, 10.0, col)
	draw_circle(c + Vector2(-3, -3), 3.5, Color(1.0, 1.0, 1.0, 0.6))

func _draw_space_jet(c: Vector2):
	match item_id:
		"interceptor":
			draw_polygon(PackedVector2Array([
				c + Vector2(0, -14),
				c + Vector2(-12, 8),
				c + Vector2(-6, 5),
				c + Vector2(0, 10),
				c + Vector2(6, 5),
				c + Vector2(12, 8)
			]), PackedColorArray([Color(1.0, 0.25, 0.2)]))
			draw_circle(c + Vector2(0, -2), 2.5, Color(1.0, 0.9, 0.2))
		"plasma_cruiser":
			draw_rect(Rect2(c.x - 9, c.y - 7, 18, 15), Color(0.1, 0.7, 0.4))
			draw_polygon(PackedVector2Array([c + Vector2(0, -13), c + Vector2(-9, -7), c + Vector2(9, -7)]), PackedColorArray([Color(0.15, 0.85, 0.5)]))
			draw_circle(c, 3.0, Color(0.3, 1.0, 0.7))
		"phantom_bomber":
			draw_polygon(PackedVector2Array([
				c + Vector2(0, -13),
				c + Vector2(-14, 8),
				c + Vector2(0, 4),
				c + Vector2(14, 8)
			]), PackedColorArray([Color(0.35, 0.15, 0.55)]))
			draw_line(c + Vector2(-11, 6), c + Vector2(0, -9), Color(0.9, 0.2, 0.8), 1.5)
			draw_line(c + Vector2(11, 6), c + Vector2(0, -9), Color(0.9, 0.2, 0.8), 1.5)
		"golden_valkyrie":
			draw_polygon(PackedVector2Array([
				c + Vector2(0, -15),
				c + Vector2(-13, 8),
				c + Vector2(0, 10),
				c + Vector2(13, 8)
			]), PackedColorArray([Color(1.0, 0.82, 0.1)]))
			draw_circle(c + Vector2(0, -1), 3.0, Color(0.2, 0.9, 1.0))
		_: # starfighter
			draw_polygon(PackedVector2Array([
				c + Vector2(0, -13),
				c + Vector2(-11, 9),
				c + Vector2(-4, 6),
				c + Vector2(0, 9),
				c + Vector2(4, 6),
				c + Vector2(11, 9)
			]), PackedColorArray([Color(0.2, 0.6, 1.0)]))
			draw_circle(c + Vector2(0, -1), 2.5, Color(0.8, 0.95, 1.0))

func _draw_brick_paddle(c: Vector2):
	var col = Color(0.2, 0.9, 1.0)
	if item_id == "plasma_blade":
		col = Color(1.0, 0.2, 0.35)
	elif item_id == "golden_ingot":
		col = Color(1.0, 0.85, 0.15)
	elif item_id == "fire_striker":
		col = Color(1.0, 0.5, 0.05)

	draw_rect(Rect2(c.x - 16, c.y - 4, 32, 8), col)
	draw_rect(Rect2(c.x - 14, c.y - 2, 28, 4), Color(1, 1, 1, 0.4))

func _draw_brick_ball(c: Vector2):
	var col = Color.WHITE
	if item_id == "fireball_comet":
		col = Color(1.0, 0.45, 0.1)
	elif item_id == "neon_prism":
		col = Color(0.9, 0.2, 1.0)

	draw_circle(c, 7.5, col)
	draw_circle(c + Vector2(-2, -2), 2.5, Color(1, 1, 1, 0.7))

func _draw_brick_arena_thumb(c: Vector2, id: String):
	var wall = Color("1e293b")
	var border = Color("38bdf8")
	match id:
		"emerald_matrix":
			wall = Color(0.04, 0.12, 0.08)
			border = Color(0.1, 0.85, 0.45)
		"crimson_chasm":
			wall = Color(0.15, 0.04, 0.05)
			border = Color(1.0, 0.25, 0.3)

	draw_rect(Rect2(c.x - 16, c.y - 16, 32, 32), Color(0.05, 0.05, 0.08))
	draw_rect(Rect2(c.x - 16, c.y - 16, 32, 6), wall)
	draw_line(Vector2(c.x - 16, c.y - 10), Vector2(c.x + 16, c.y - 10), border, 1.5)
	draw_rect(Rect2(c.x - 16, c.y - 10, 4, 26), wall)
	draw_rect(Rect2(c.x + 12, c.y - 10, 4, 26), wall)

func _draw_hamster_animal(c: Vector2):
	match item_id:
		"bunny":
			# Bunny Ears
			draw_circle(c + Vector2(-5, -12), 4.5, Color.WHITE)
			draw_circle(c + Vector2(5, -12), 4.5, Color.WHITE)
			draw_circle(c + Vector2(-5, -12), 2.5, Color(1.0, 0.65, 0.75))
			draw_circle(c + Vector2(5, -12), 2.5, Color(1.0, 0.65, 0.75))
			# Face
			draw_circle(c, 8.0, Color.WHITE)
			draw_circle(c + Vector2(-3, -2), 1.5, Color.BLACK)
			draw_circle(c + Vector2(3, -2), 1.5, Color.BLACK)
			draw_circle(c + Vector2(0, 1), 1.5, Color(1.0, 0.5, 0.6))
		"kitty":
			# Cat Ears
			draw_polygon(PackedVector2Array([c + Vector2(-8, -4), c + Vector2(-6, -13), c + Vector2(-1, -6)]), PackedColorArray([Color(0.96, 0.68, 0.36)]))
			draw_polygon(PackedVector2Array([c + Vector2(1, -6), c + Vector2(6, -13), c + Vector2(8, -4)]), PackedColorArray([Color(0.96, 0.68, 0.36)]))
			draw_circle(c, 8.0, Color(0.96, 0.68, 0.36))
			draw_circle(c + Vector2(-3, -2), 1.5, Color.BLACK)
			draw_circle(c + Vector2(3, -2), 1.5, Color.BLACK)
			draw_circle(c + Vector2(0, 1), 1.2, Color(1.0, 0.5, 0.6))
		"panda":
			# Panda Ears
			draw_circle(c + Vector2(-6, -8), 3.5, Color(0.12, 0.12, 0.15))
			draw_circle(c + Vector2(6, -8), 3.5, Color(0.12, 0.12, 0.15))
			draw_circle(c, 8.0, Color.WHITE)
			draw_circle(c + Vector2(-3, -2), 2.5, Color(0.12, 0.12, 0.15))
			draw_circle(c + Vector2(3, -2), 2.5, Color(0.12, 0.12, 0.15))
			draw_circle(c + Vector2(-3, -2), 1.0, Color.WHITE)
			draw_circle(c + Vector2(3, -2), 1.0, Color.WHITE)
			draw_circle(c + Vector2(0, 1), 1.5, Color(0.12, 0.12, 0.15))
		"fox":
			draw_polygon(PackedVector2Array([c + Vector2(-8, -4), c + Vector2(-6, -13), c + Vector2(-1, -6)]), PackedColorArray([Color(0.15, 0.15, 0.18)]))
			draw_polygon(PackedVector2Array([c + Vector2(1, -6), c + Vector2(6, -13), c + Vector2(8, -4)]), PackedColorArray([Color(0.15, 0.15, 0.18)]))
			draw_circle(c, 8.0, Color(0.92, 0.45, 0.15))
			draw_circle(c + Vector2(-3, 2), 3.0, Color.WHITE)
			draw_circle(c + Vector2(3, 2), 3.0, Color.WHITE)
			draw_circle(c + Vector2(-3, -2), 1.5, Color(0.1, 0.1, 0.1))
			draw_circle(c + Vector2(3, -2), 1.5, Color(0.1, 0.1, 0.1))
			draw_circle(c + Vector2(0, 1), 1.5, Color(0.1, 0.1, 0.1))
		_: # hamster
			draw_circle(c + Vector2(-6, -7), 3.5, Color(0.93, 0.66, 0.38))
			draw_circle(c + Vector2(6, -7), 3.5, Color(0.93, 0.66, 0.38))
			draw_circle(c, 8.0, Color(0.93, 0.66, 0.38))
			draw_circle(c + Vector2(-3, -2), 1.5, Color(0.08, 0.08, 0.08))
			draw_circle(c + Vector2(3, -2), 1.5, Color(0.08, 0.08, 0.08))
			draw_circle(c + Vector2(-5, 0), 2.0, Color(1.0, 0.5, 0.6, 0.6))
			draw_circle(c + Vector2(5, 0), 2.0, Color(1.0, 0.5, 0.6, 0.6))
			draw_circle(c + Vector2(0, 0), 1.2, Color(0.25, 0.12, 0.08))
			draw_rect(Rect2(c.x - 1.5, c.y + 1, 1.2, 2.5), Color.WHITE)
			draw_rect(Rect2(c.x + 0.3, c.y + 1, 1.2, 2.5), Color.WHITE)

func _draw_bounce_ground_thumb(c: Vector2, id: String):
	var bg_col = Color(0.06, 0.08, 0.12)
	var plat_col = Color(0.2, 0.6, 0.3)
	var deco_col = Color(0.3, 0.8, 0.4)

	match id:
		"level_2":
			bg_col = Color(0.12, 0.06, 0.08)
			plat_col = Color(0.5, 0.25, 0.2)
			deco_col = Color(0.9, 0.2, 0.2)
		"level_3":
			bg_col = Color(0.05, 0.12, 0.2)
			plat_col = Color(0.2, 0.4, 0.7)
			deco_col = Color(0.3, 0.8, 1.0)
		"level_4":
			bg_col = Color(0.1, 0.04, 0.16)
			plat_col = Color(0.4, 0.2, 0.6)
			deco_col = Color(0.8, 0.3, 1.0)
		"level_5":
			bg_col = Color(0.16, 0.12, 0.04)
			plat_col = Color(0.7, 0.55, 0.15)
			deco_col = Color(1.0, 0.85, 0.25)

	draw_rect(Rect2(c.x - 18, c.y - 18, 36, 36), bg_col)
	draw_rect(Rect2(c.x - 15, c.y + 4, 30, 8), plat_col)
	draw_rect(Rect2(c.x - 8, c.y - 8, 16, 5), deco_col)
	if id == "level_2":
		draw_line(Vector2(c.x - 12, c.y + 3), Vector2(c.x - 9, c.y), Color.RED, 1.5)
		draw_line(Vector2(c.x - 9, c.y), Vector2(c.x - 6, c.y + 3), Color.RED, 1.5)
		draw_line(Vector2(c.x + 6, c.y + 3), Vector2(c.x + 9, c.y), Color.RED, 1.5)
		draw_line(Vector2(c.x + 9, c.y), Vector2(c.x + 12, c.y + 3), Color.RED, 1.5)
	else:
		draw_circle(Vector2(c.x, c.y - 12), 2.5, deco_col)

