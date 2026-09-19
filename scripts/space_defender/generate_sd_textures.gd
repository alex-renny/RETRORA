extends SceneTree

func _init():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://assets/space_defender"):
		dir.make_dir_recursive("res://assets/space_defender")

	generate_player_ship("res://assets/space_defender/player_ship.png")
	generate_enemy_basic("res://assets/space_defender/enemy_basic.png")
	generate_enemy_fast("res://assets/space_defender/enemy_fast.png")
	generate_enemy_tank("res://assets/space_defender/enemy_tank.png")
	generate_enemy_shooter("res://assets/space_defender/enemy_shooter.png")
	generate_boss("res://assets/space_defender/boss_mothership.png")
	generate_laser("res://assets/space_defender/laser_player.png", Color(0.2, 0.9, 1.0, 1.0), 4, 14)
	generate_laser("res://assets/space_defender/laser_enemy.png", Color(1.0, 0.2, 0.2, 1.0), 4, 12)
	generate_laser("res://assets/space_defender/laser_boss.png", Color(0.9, 0.2, 0.9, 1.0), 8, 16)
	print("Space Defender textures generated successfully!")
	quit()

func generate_player_ship(path: String):
	var w = 28
	var h = 32
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var white = Color(0.95, 0.95, 1.0, 1.0)
	var blue = Color(0.15, 0.5, 0.95, 1.0)
	var dark_blue = Color(0.08, 0.25, 0.65, 1.0)
	var cyan = Color(0.2, 0.85, 1.0, 1.0)
	var red = Color(0.95, 0.2, 0.2, 1.0)
	var engine = Color(1.0, 0.7, 0.1, 1.0)

	# Fuselage (triangular)
	for y in range(4, 28):
		var span = int((y - 4) * 0.45)
		for x in range(14 - span, 14 + span):
			img.set_pixel(x, y, white)

	# Wings
	for y in range(16, 28):
		var w_span = int((y - 16) * 1.0)
		for x in range(14 - 4 - w_span, 14 + 4 + w_span):
			if x >= 0 and x < w:
				img.set_pixel(x, y, blue)

	# Wing edges & details
	for y in range(22, 28):
		img.set_pixel(1, y, red)
		img.set_pixel(2, y, red)
		img.set_pixel(w - 2, y, red)
		img.set_pixel(w - 3, y, red)

	# Cockpit glass
	for y in range(10, 18):
		for x in range(12, 16):
			img.set_pixel(x, y, cyan)

	# Engine flame
	for y in range(28, 32):
		img.set_pixel(12, y, engine)
		img.set_pixel(13, y, engine)
		img.set_pixel(14, y, engine)
		img.set_pixel(15, y, engine)

	img.save_png(path)

func generate_enemy_basic(path: String):
	var w = 22
	var h = 22
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var green = Color(0.25, 0.85, 0.3, 1.0)
	var dark_green = Color(0.1, 0.45, 0.15, 1.0)
	var eye = Color(1.0, 0.2, 0.2, 1.0)

	# Invader bug body
	for y in range(4, 18):
		for x in range(3, 19):
			if (x + y) % 2 == 0 or (x >= 6 and x <= 15):
				img.set_pixel(x, y, green)
			else:
				img.set_pixel(x, y, dark_green)

	# Eyes
	img.set_pixel(7, 10, eye)
	img.set_pixel(8, 10, eye)
	img.set_pixel(13, 10, eye)
	img.set_pixel(14, 10, eye)

	# Mandibles/cannons at bottom
	img.set_pixel(5, 19, green)
	img.set_pixel(5, 20, green)
	img.set_pixel(16, 19, green)
	img.set_pixel(16, 20, green)

	img.save_png(path)

func generate_enemy_fast(path: String):
	var w = 18
	var h = 22
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var red = Color(0.95, 0.2, 0.2, 1.0)
	var yellow = Color(1.0, 0.85, 0.1, 1.0)
	var dark_red = Color(0.55, 0.08, 0.08, 1.0)

	# Dart arrowhead pointing down
	for y in range(0, 20):
		var span = int((20 - y) * 0.42)
		for x in range(9 - span, 9 + span):
			img.set_pixel(x, y, red)

	# Cockpit / core
	for y in range(6, 14):
		img.set_pixel(8, y, yellow)
		img.set_pixel(9, y, yellow)

	img.save_png(path)

func generate_enemy_tank(path: String):
	var w = 32
	var h = 30
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var purple = Color(0.65, 0.2, 0.85, 1.0)
	var dark_purple = Color(0.35, 0.08, 0.45, 1.0)
	var core = Color(0.1, 0.9, 0.95, 1.0)

	# Heavy armored block
	for y in range(4, 26):
		for x in range(4, 28):
			img.set_pixel(x, y, purple)

	# Armor plates
	for y in range(6, 24):
		img.set_pixel(4, y, dark_purple)
		img.set_pixel(5, y, dark_purple)
		img.set_pixel(26, y, dark_purple)
		img.set_pixel(27, y, dark_purple)

	# Twin Cannons extending down
	for y in range(24, 30):
		img.set_pixel(8, y, dark_purple)
		img.set_pixel(9, y, dark_purple)
		img.set_pixel(22, y, dark_purple)
		img.set_pixel(23, y, dark_purple)

	# Glowing reactor core
	for y in range(12, 18):
		for x in range(13, 19):
			img.set_pixel(x, y, core)

	img.save_png(path)

func generate_enemy_shooter(path: String):
	var w = 24
	var h = 24
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var orange = Color(1.0, 0.6, 0.1, 1.0)
	var dark_orange = Color(0.65, 0.35, 0.05, 1.0)
	var eye = Color(0.2, 0.9, 1.0, 1.0)

	# Round sniper pod
	var center = Vector2(11.5, 11.5)
	for y in range(w):
		for x in range(h):
			if Vector2(x, y).distance_to(center) <= 9.5:
				img.set_pixel(x, y, orange)

	# Big targeting optic eye
	for y in range(9, 15):
		for x in range(9, 15):
			img.set_pixel(x, y, eye)

	# Laser barrel tip
	for y in range(20, 24):
		img.set_pixel(11, y, dark_orange)
		img.set_pixel(12, y, dark_orange)

	img.save_png(path)

func generate_boss(path: String):
	var w = 64
	var h = 54
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var hull = Color(0.35, 0.12, 0.45, 1.0)
	var dark_hull = Color(0.2, 0.06, 0.28, 1.0)
	var neon = Color(0.9, 0.15, 0.6, 1.0)
	var core = Color(0.2, 0.95, 0.85, 1.0)
	var yellow = Color(1.0, 0.85, 0.1, 1.0)

	# Massive Mothership Frame
	for y in range(6, 44):
		var span = int((y - 6) * 0.7) + 14
		span = min(span, 28)
		for x in range(32 - span, 32 + span):
			img.set_pixel(x, y, hull)

	# Outer wing wings & armor plates
	for y in range(10, 48):
		img.set_pixel(32 - 27, y, dark_hull)
		img.set_pixel(32 + 26, y, dark_hull)
		img.set_pixel(32 - 28, y, neon)
		img.set_pixel(32 + 27, y, neon)

	# Heavy triple cannon batteries
	for y in range(40, 52):
		img.set_pixel(14, y, dark_hull)
		img.set_pixel(15, y, yellow)
		img.set_pixel(31, y, dark_hull)
		img.set_pixel(32, y, yellow)
		img.set_pixel(48, y, dark_hull)
		img.set_pixel(49, y, yellow)

	# Glowing Pulsing Mothership Core
	for y in range(18, 30):
		for x in range(26, 38):
			img.set_pixel(x, y, core)

	img.save_png(path)

func generate_laser(path: String, color: Color, w: int, h: int):
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	img.save_png(path)
