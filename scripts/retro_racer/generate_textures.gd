extends SceneTree

func _init():
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://assets/retro_racer"):
		dir.make_dir_recursive("res://assets/retro_racer")

	generate_player_car("res://assets/retro_racer/player_car.png")
	generate_traffic_car("res://assets/retro_racer/traffic_sedan.png", Color(0.15, 0.45, 0.9), Color(0.08, 0.25, 0.6))
	generate_traffic_compact("res://assets/retro_racer/traffic_compact.png")
	generate_traffic_truck("res://assets/retro_racer/traffic_truck.png")
	generate_road_stripe("res://assets/retro_racer/road_stripe.png")
	print("All Retro Racer textures generated successfully!")
	quit()

func generate_player_car(path: String):
	var w = 24
	var h = 44
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var red = Color(0.9, 0.15, 0.15, 1)
	var dark_red = Color(0.65, 0.08, 0.08, 1)
	var windshield = Color(0.3, 0.75, 0.95, 1)
	var black = Color(0.12, 0.12, 0.14, 1)
	var yellow = Color(1.0, 0.9, 0.2, 1)

	# Wheels
	for y in range(6, 14):
		for x in range(1, 4):
			img.set_pixel(x, y, black)
			img.set_pixel(w - 1 - x, y, black)
	for y in range(28, 36):
		for x in range(1, 4):
			img.set_pixel(x, y, black)
			img.set_pixel(w - 1 - x, y, black)

	# Body
	for y in range(4, 40):
		for x in range(4, w - 4):
			img.set_pixel(x, y, red)

	# Borders / Shadow
	for y in range(4, 40):
		img.set_pixel(4, y, dark_red)
		img.set_pixel(w - 5, y, dark_red)

	# Front windshield
	for y in range(12, 17):
		for x in range(6, w - 6):
			img.set_pixel(x, y, windshield)

	# Roof
	for y in range(17, 26):
		for x in range(6, w - 6):
			img.set_pixel(x, y, dark_red)

	# Rear windshield
	for y in range(26, 30):
		for x in range(6, w - 6):
			img.set_pixel(x, y, windshield)

	# Headlights
	img.set_pixel(5, 4, yellow)
	img.set_pixel(6, 4, yellow)
	img.set_pixel(w - 6, 4, yellow)
	img.set_pixel(w - 7, 4, yellow)

	img.save_png(path)

func generate_traffic_car(path: String, main_col: Color, shadow_col: Color):
	var w = 24
	var h = 44
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var windshield = Color(0.2, 0.55, 0.7, 1)
	var black = Color(0.12, 0.12, 0.14, 1)
	var red = Color(0.9, 0.1, 0.1, 1)

	# Wheels
	for y in range(6, 14):
		for x in range(1, 4):
			img.set_pixel(x, y, black)
			img.set_pixel(w - 1 - x, y, black)
	for y in range(28, 36):
		for x in range(1, 4):
			img.set_pixel(x, y, black)
			img.set_pixel(w - 1 - x, y, black)

	# Body
	for y in range(4, 40):
		for x in range(4, w - 4):
			img.set_pixel(x, y, main_col)

	for y in range(4, 40):
		img.set_pixel(4, y, shadow_col)
		img.set_pixel(w - 5, y, shadow_col)

	# Windows
	for y in range(12, 17):
		for x in range(6, w - 6):
			img.set_pixel(x, y, windshield)
	for y in range(17, 26):
		for x in range(6, w - 6):
			img.set_pixel(x, y, shadow_col)
	for y in range(26, 30):
		for x in range(6, w - 6):
			img.set_pixel(x, y, windshield)

	# Taillights (traffic moves down, so rear is facing player at bottom)
	img.set_pixel(5, 39, red)
	img.set_pixel(6, 39, red)
	img.set_pixel(w - 6, 39, red)
	img.set_pixel(w - 7, 39, red)

	img.save_png(path)

func generate_traffic_compact(path: String):
	var w = 20
	var h = 36
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var green = Color(0.2, 0.75, 0.35, 1)
	var dark_green = Color(0.1, 0.45, 0.2, 1)
	var windshield = Color(0.3, 0.6, 0.7, 1)
	var black = Color(0.12, 0.12, 0.14, 1)
	var red = Color(0.9, 0.1, 0.1, 1)

	# Wheels
	for y in range(5, 11):
		for x in range(1, 3):
			img.set_pixel(x, y, black)
			img.set_pixel(w - 1 - x, y, black)
	for y in range(24, 30):
		for x in range(1, 3):
			img.set_pixel(x, y, black)
			img.set_pixel(w - 1 - x, y, black)

	# Body
	for y in range(3, 33):
		for x in range(3, w - 3):
			img.set_pixel(x, y, green)
	for y in range(3, 33):
		img.set_pixel(3, y, dark_green)
		img.set_pixel(w - 4, y, dark_green)

	# Windows
	for y in range(10, 14):
		for x in range(5, w - 5):
			img.set_pixel(x, y, windshield)
	for y in range(14, 22):
		for x in range(5, w - 5):
			img.set_pixel(x, y, dark_green)
	for y in range(22, 25):
		for x in range(5, w - 5):
			img.set_pixel(x, y, windshield)

	# Taillights
	img.set_pixel(4, 32, red)
	img.set_pixel(w - 5, 32, red)

	img.save_png(path)

func generate_traffic_truck(path: String):
	var w = 26
	var h = 52
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var orange = Color(0.9, 0.55, 0.1, 1)
	var dark_orange = Color(0.65, 0.35, 0.05, 1)
	var cab = Color(0.95, 0.8, 0.2, 1)
	var windshield = Color(0.2, 0.45, 0.6, 1)
	var black = Color(0.12, 0.12, 0.14, 1)

	# 6 Wheels
	for y_pair in [[6, 12], [26, 32], [38, 44]]:
		for y in range(y_pair[0], y_pair[1]):
			for x in range(1, 4):
				img.set_pixel(x, y, black)
				img.set_pixel(w - 1 - x, y, black)

	# Cargo box
	for y in range(14, 49):
		for x in range(4, w - 4):
			img.set_pixel(x, y, orange)
	for y in range(14, 49):
		img.set_pixel(4, y, dark_orange)
		img.set_pixel(w - 5, y, dark_orange)

	# Cab
	for y in range(3, 13):
		for x in range(5, w - 5):
			img.set_pixel(x, y, cab)
	for y in range(5, 9):
		for x in range(7, w - 7):
			img.set_pixel(x, y, windshield)

	# Rear lights
	img.set_pixel(5, 48, Color(0.9, 0.1, 0.1, 1))
	img.set_pixel(w - 6, 48, Color(0.9, 0.1, 0.1, 1))

	img.save_png(path)

func generate_road_stripe(path: String):
	var img = Image.create(4, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	img.save_png(path)
