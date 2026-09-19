extends SceneTree

func _init():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://assets/brick_breaker"):
		dir.make_dir_recursive("res://assets/brick_breaker")

	generate_paddle("res://assets/brick_breaker/paddle.png", 64, 14)
	generate_paddle("res://assets/brick_breaker/paddle_wide.png", 88, 14)
	generate_ball("res://assets/brick_breaker/ball.png")
	generate_brick("res://assets/brick_breaker/brick_normal.png", Color("00b4d8"), Color("0077b6"), Color("90e0ef"))
	generate_brick_strong("res://assets/brick_breaker/brick_strong.png", false)
	generate_brick_strong("res://assets/brick_breaker/brick_strong_cracked.png", true)
	generate_brick_gold("res://assets/brick_breaker/brick_bonus.png")
	generate_brick_tnt("res://assets/brick_breaker/brick_explosive.png")

	generate_capsule("res://assets/brick_breaker/powerup_wide.png", Color("00b4d8"), "W")
	generate_capsule("res://assets/brick_breaker/powerup_multi.png", Color("38b000"), "3")
	generate_capsule("res://assets/brick_breaker/powerup_slow.png", Color("ffb703"), "S")
	generate_capsule("res://assets/brick_breaker/powerup_life.png", Color("e63946"), "+")

	print("Brick Breaker textures generated successfully!")
	quit()

func generate_paddle(path: String, w: int, h: int):
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var metallic = Color(0.2, 0.6, 0.95, 1.0)
	var dark_metal = Color(0.1, 0.3, 0.6, 1.0)
	var bumper = Color(0.95, 0.2, 0.2, 1.0)
	var highlight = Color(0.7, 0.9, 1.0, 1.0)

	# Main rounded body
	for y in range(2, h - 2):
		for x in range(2, w - 2):
			img.set_pixel(x, y, metallic)

	# Top highlight
	for x in range(4, w - 4):
		img.set_pixel(x, 2, highlight)

	# Bottom shade
	for x in range(3, w - 3):
		img.set_pixel(x, h - 3, dark_metal)

	# Red rubber end bumpers
	for y in range(3, h - 3):
		img.set_pixel(2, y, bumper)
		img.set_pixel(3, y, bumper)
		img.set_pixel(w - 3, y, bumper)
		img.set_pixel(w - 4, y, bumper)

	img.save_png(path)

func generate_ball(path: String):
	var size = 10
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var white = Color(1.0, 1.0, 1.0, 1.0)
	var grey = Color(0.7, 0.75, 0.85, 1.0)
	var dark = Color(0.4, 0.45, 0.55, 1.0)
	var center = Vector2(4.5, 4.5)

	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 4.2:
				img.set_pixel(x, y, grey)

	# Highlight
	img.set_pixel(3, 3, white)
	img.set_pixel(4, 3, white)
	img.set_pixel(3, 4, white)

	# Shading
	img.set_pixel(6, 6, dark)
	img.set_pixel(6, 5, dark)
	img.set_pixel(5, 6, dark)

	img.save_png(path)

func generate_brick(path: String, main_c: Color, shadow_c: Color, high_c: Color):
	var w = 32
	var h = 14
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(main_c)

	# Borders
	for x in range(w):
		img.set_pixel(x, 0, high_c)
		img.set_pixel(x, 1, high_c)
		img.set_pixel(x, h - 1, shadow_c)
		img.set_pixel(x, h - 2, shadow_c)

	for y in range(h):
		img.set_pixel(0, y, high_c)
		img.set_pixel(w - 1, y, shadow_c)

	img.save_png(path)

func generate_brick_strong(path: String, cracked: bool):
	var w = 32
	var h = 14
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var steel = Color(0.65, 0.68, 0.72, 1.0)
	var dark = Color(0.35, 0.38, 0.42, 1.0)
	var high = Color(0.9, 0.92, 0.95, 1.0)
	img.fill(steel)

	# Borders
	for x in range(w):
		img.set_pixel(x, 0, high)
		img.set_pixel(x, h - 1, dark)
	for y in range(h):
		img.set_pixel(0, y, high)
		img.set_pixel(w - 1, y, dark)

	# Rivets
	var rivet = Color(0.2, 0.22, 0.25, 1.0)
	img.set_pixel(3, 3, rivet)
	img.set_pixel(w - 4, 3, rivet)
	img.set_pixel(3, h - 4, rivet)
	img.set_pixel(w - 4, h - 4, rivet)

	if cracked:
		# Dark jagged crack across center
		var crack_col = Color(0.15, 0.15, 0.18, 1.0)
		var pts = [[10, 4], [12, 6], [16, 7], [18, 9], [22, 11]]
		for pt in pts:
			img.set_pixel(pt[0], pt[1], crack_col)
			img.set_pixel(pt[0] + 1, pt[1], crack_col)

	img.save_png(path)

func generate_brick_gold(path: String):
	var w = 32
	var h = 14
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var gold = Color(0.95, 0.8, 0.15, 1.0)
	var shadow = Color(0.65, 0.48, 0.05, 1.0)
	var high = Color(1.0, 0.95, 0.6, 1.0)
	img.fill(gold)

	for x in range(w):
		img.set_pixel(x, 0, high)
		img.set_pixel(x, h - 1, shadow)
	for y in range(h):
		img.set_pixel(0, y, high)
		img.set_pixel(w - 1, y, shadow)

	# Diamond center
	var white = Color(1.0, 1.0, 1.0, 1.0)
	img.set_pixel(15, 5, white)
	img.set_pixel(16, 5, white)
	img.set_pixel(14, 6, white)
	img.set_pixel(17, 6, white)
	img.set_pixel(15, 7, shadow)
	img.set_pixel(16, 7, shadow)

	img.save_png(path)

func generate_brick_tnt(path: String):
	var w = 32
	var h = 14
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var red = Color(0.9, 0.15, 0.15, 1.0)
	var dark = Color(0.45, 0.05, 0.05, 1.0)
	var yellow = Color(1.0, 0.85, 0.1, 1.0)
	img.fill(red)

	for x in range(w):
		img.set_pixel(x, 0, yellow)
		img.set_pixel(x, h - 1, dark)

	# TNT stripe pattern
	for x in range(w):
		if (x / 4) % 2 == 0:
			for y in range(4, 10):
				img.set_pixel(x, y, yellow)

	img.save_png(path)

func generate_capsule(path: String, col: Color, char_symbol: String):
	var size = 16
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var center = Vector2(7.5, 7.5)
	for y in range(size):
		for x in range(size):
			if Vector2(x, y).distance_to(center) <= 6.8:
				img.set_pixel(x, y, col)

	# Center white dot / indicator
	var white = Color(1.0, 1.0, 1.0, 1.0)
	img.set_pixel(7, 7, white)
	img.set_pixel(8, 7, white)
	img.set_pixel(7, 8, white)
	img.set_pixel(8, 8, white)

	img.save_png(path)
