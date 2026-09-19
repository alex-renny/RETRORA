class_name BrickLevelData

# Returns an array of brick definitions: [{"type": int, "pos": Vector2}]
static func get_level(level_idx: int) -> Dictionary:
	match level_idx:
		1:
			return {
				"name": "Level 1: Classical Wall",
				"bricks": _build_level_1()
			}
		2:
			return {
				"name": "Level 2: The Fortress",
				"bricks": _build_level_2()
			}
		3:
			return {
				"name": "Level 3: Explosive Chain",
				"bricks": _build_level_3()
			}
		4:
			return {
				"name": "Level 4: Alien Invader",
				"bricks": _build_level_4()
			}
		5:
			return {
				"name": "Level 5: The Grand Vault",
				"bricks": _build_level_5()
			}
		_:
			return get_level(1)

static func _build_level_1() -> Array:
	var list = []
	for row in range(4):
		for col in range(8):
			var x = 54 + col * 36
			var y = 90 + row * 18
			var type = 0 # Normal
			if (col == 3 or col == 4) and row == 1:
				type = 2 # Bonus
			list.append({"type": type, "pos": Vector2(x, y)})
	return list

static func _build_level_2() -> Array:
	var list = []
	for row in range(5):
		for col in range(8):
			var x = 54 + col * 36
			var y = 85 + row * 18
			var type = 0
			# Outer shield of strong steel bricks
			if row == 0 or row == 4 or col == 0 or col == 7:
				type = 1 # Strong
			elif row == 2 and (col == 3 or col == 4):
				type = 2 # Bonus
			list.append({"type": type, "pos": Vector2(x, y)})
	return list

static func _build_level_3() -> Array:
	var list = []
	for row in range(5):
		for col in range(8):
			var x = 54 + col * 36
			var y = 80 + row * 18
			var type = 0
			# Strategic TNT placement
			if (col == 2 or col == 5) and (row == 1 or row == 3):
				type = 3 # Explosive
			elif row == 2 and (col == 0 or col == 7):
				type = 1 # Strong
			elif row == 0 and (col == 3 or col == 4):
				type = 2 # Bonus
			list.append({"type": type, "pos": Vector2(x, y)})
	return list

static func _build_level_4() -> Array:
	# Space invader shape
	var grid = [
		[0, 1, 0, 0, 0, 0, 1, 0],
		[0, 0, 1, 1, 1, 1, 0, 0],
		[1, 1, 1, 2, 2, 1, 1, 1],
		[1, 0, 1, 3, 3, 1, 0, 1],
		[0, 1, 0, 1, 1, 0, 1, 0]
	]
	var list = []
	for row in range(grid.size()):
		for col in range(grid[row].size()):
			var val = grid[row][col]
			if val > 0:
				var x = 54 + col * 36
				var y = 80 + row * 18
				list.append({"type": val - 1, "pos": Vector2(x, y)})
	return list

static func _build_level_5() -> Array:
	var list = []
	for row in range(6):
		var span = 8 - row
		for col in range(span):
			var x = 54 + (col + row * 0.5) * 36
			var y = 75 + row * 18
			var type = 0
			if row == 0:
				type = 1 # Strong armor roof
			elif row == 2 and col % 2 == 1:
				type = 3 # Explosive core
			elif row == 4:
				type = 2 # Gold bonus treasures
			list.append({"type": type, "pos": Vector2(x, y)})
	return list
