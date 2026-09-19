extends SceneTree

func _init():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://assets/sky_hopper"):
		dir.make_dir_recursive("res://assets/sky_hopper")

	generate_player("res://assets/sky_hopper/player_flyer.png")
	generate_pipe_body("res://assets/sky_hopper/pipe_body.png")
	generate_pipe_cap("res://assets/sky_hopper/pipe_cap.png")
	print("Sky Hopper textures generated successfully!")
	quit()

func generate_player(path: String):
	var w = 28
	var h = 22
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var yellow = Color(0.98, 0.82, 0.15, 1.0)
	var dark_yellow = Color(0.85, 0.65, 0.1, 1.0)
	var orange = Color(0.95, 0.45, 0.1, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)
	var black = Color(0.1, 0.1, 0.12, 1.0)

	# Main round body
	for y in range(4, 18):
		for x in range(4, 22):
			img.set_pixel(x, y, yellow)

	# Shading bottom
	for y in range(14, 18):
		for x in range(5, 21):
			img.set_pixel(x, y, dark_yellow)

	# Wing
	for y in range(8, 14):
		for x in range(6, 13):
			img.set_pixel(x, y, orange)

	# Eye
	for y in range(6, 11):
		for x in range(16, 21):
			img.set_pixel(x, y, white)
	img.set_pixel(18, 8, black)
	img.set_pixel(19, 8, black)
	img.set_pixel(18, 9, black)
	img.set_pixel(19, 9, black)

	# Beak
	for y in range(10, 15):
		for x in range(21, 26):
			img.set_pixel(x, y, orange)

	img.save_png(path)

func generate_pipe_body(path: String):
	var w = 48
	var h = 32
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var green = Color(0.28, 0.72, 0.22, 1.0)
	var light_green = Color(0.45, 0.88, 0.35, 1.0)
	var dark_green = Color(0.15, 0.45, 0.12, 1.0)
	var outline = Color(0.08, 0.22, 0.06, 1.0)

	for y in range(h):
		for x in range(w):
			if x == 0 or x == w - 1:
				img.set_pixel(x, y, outline)
			elif x >= 4 and x <= 9:
				img.set_pixel(x, y, light_green)
			elif x >= w - 10:
				img.set_pixel(x, y, dark_green)
			else:
				img.set_pixel(x, y, green)

	img.save_png(path)

func generate_pipe_cap(path: String):
	var w = 54
	var h = 24
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var green = Color(0.28, 0.72, 0.22, 1.0)
	var light_green = Color(0.45, 0.88, 0.35, 1.0)
	var dark_green = Color(0.15, 0.45, 0.12, 1.0)
	var outline = Color(0.08, 0.22, 0.06, 1.0)

	for y in range(h):
		for x in range(w):
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				img.set_pixel(x, y, outline)
			elif x >= 5 and x <= 11:
				img.set_pixel(x, y, light_green)
			elif x >= w - 12:
				img.set_pixel(x, y, dark_green)
			else:
				img.set_pixel(x, y, green)

	img.save_png(path)
