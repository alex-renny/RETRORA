extends SceneTree

func _init():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://assets/bounce_quest"):
		dir.make_dir_recursive("res://assets/bounce_quest")

	generate_ball("res://assets/bounce_quest/ball.png")
	generate_crystal("res://assets/bounce_quest/crystal.png")
	generate_spikes("res://assets/bounce_quest/spikes.png")
	generate_tile("res://assets/bounce_quest/platform_tile.png")
	generate_portal("res://assets/bounce_quest/exit_portal.png")
	print("Bounce Quest textures generated successfully!")
	quit()

func generate_ball(path: String):
	var size = 20
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var red = Color(0.92, 0.22, 0.22, 1.0)
	var dark_red = Color(0.65, 0.12, 0.12, 1.0)
	var highlight = Color(1.0, 0.75, 0.75, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)

	var center = Vector2(9.5, 9.5)
	var radius = 9.0

	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				img.set_pixel(x, y, red)

	# Shadow bottom-right
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius and (x > 11 or y > 11) and not (x < 8 and y < 8):
				img.set_pixel(x, y, dark_red)

	# Highlight top-left
	img.set_pixel(5, 5, white)
	img.set_pixel(6, 5, white)
	img.set_pixel(5, 6, white)
	img.set_pixel(6, 6, highlight)
	img.set_pixel(7, 5, highlight)
	img.set_pixel(5, 7, highlight)

	img.save_png(path)

func generate_crystal(path: String):
	var w = 14
	var h = 18
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var cyan = Color(0.15, 0.85, 0.95, 1.0)
	var dark_cyan = Color(0.08, 0.45, 0.65, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)

	# Diamond shape
	var mid_x = 6.5
	var mid_y = 8.5
	for y in range(h):
		for x in range(w):
			var dx = abs(x - mid_x) / 6.5
			var dy = abs(y - mid_y) / 8.5
			if dx + dy <= 1.0:
				if x < 7:
					img.set_pixel(x, y, cyan)
				else:
					img.set_pixel(x, y, dark_cyan)

	# Shine in center
	img.set_pixel(6, 7, white)
	img.set_pixel(6, 8, white)
	img.set_pixel(7, 7, white)

	img.save_png(path)

func generate_spikes(path: String):
	var size = 16
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var grey = Color(0.75, 0.75, 0.8, 1.0)
	var dark_grey = Color(0.4, 0.4, 0.45, 1.0)
	var tip = Color(0.95, 0.95, 1.0, 1.0)

	# Two sharp triangular spikes
	# Spike 1: x from 0 to 7, peak at x=3.5, y=0
	for y in range(size):
		var w_half = (y / 15.0) * 3.5
		for x in range(size):
			# Spike 1 (left)
			if abs(x - 3.5) <= w_half:
				img.set_pixel(x, y, dark_grey if x > 3.5 else grey)
			# Spike 2 (right)
			if abs(x - 11.5) <= w_half:
				img.set_pixel(x, y, dark_grey if x > 11.5 else grey)

	img.set_pixel(3, 0, tip)
	img.set_pixel(4, 0, tip)
	img.set_pixel(11, 0, tip)
	img.set_pixel(12, 0, tip)

	img.save_png(path)

func generate_tile(path: String):
	var size = 16
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.16, 0.14, 1.0)) # Dark earth brick

	var grass = Color(0.28, 0.72, 0.22, 1.0)
	var border = Color(0.12, 0.1, 0.08, 1.0)
	var brick_light = Color(0.32, 0.25, 0.2, 1.0)

	# Brick grid pattern
	for x in range(size):
		img.set_pixel(x, 0, grass)
		img.set_pixel(x, 1, grass)
		img.set_pixel(x, 15, border)

	for y in range(size):
		img.set_pixel(0, y, border)
		img.set_pixel(15, y, border)

	for x in range(2, 14):
		for y in range(3, 14):
			if (x + y) % 4 == 0:
				img.set_pixel(x, y, brick_light)

	img.save_png(path)

func generate_portal(path: String):
	var w = 24
	var h = 36
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var stone = Color(0.45, 0.45, 0.5, 1.0)
	var glow = Color(0.2, 0.85, 0.9, 0.9)
	var bright = Color(1.0, 1.0, 1.0, 1.0)

	# Archway
	for y in range(h):
		for x in range(w):
			if x <= 3 or x >= w - 4 or y <= 4:
				img.set_pixel(x, y, stone)
			else:
				img.set_pixel(x, y, glow)

	# Portal star in center
	img.set_pixel(11, 17, bright)
	img.set_pixel(12, 17, bright)
	img.set_pixel(11, 18, bright)
	img.set_pixel(12, 18, bright)

	img.save_png(path)
