extends Node2D

class_name BlockGrid

signal path_changed()
signal puzzle_completed()

# Grid Dimensions
var cols: int = 5
var rows: int = 5
var cell_size: float = 56.0
var grid_origin: Vector2 = Vector2.ZERO

# Board tiles: Set of Vector2i representing valid active tiles
var active_tiles: Array[Vector2i] = []
# Fixed start tile
var start_cell: Vector2i = Vector2i.ZERO

# Current continuous drawn path: Array[Vector2i]
var path: Array[Vector2i] = []

# Unlocks / Visual Theme
var theme_id: String = "electric_cyan"
var trail_id: String = "sparkle"

# Particles
var trail_sparks: Array[Dictionary] = []
var completion_burst: Array[Dictionary] = []
var is_animating_win: bool = false
var win_anim_timer: float = 0.0

# Input dragging state
var is_dragging: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	refresh_equipment()
	SaveManager.item_equipped.connect(_on_item_equipped)

func _on_item_equipped(category: String, _item_id: String) -> void:
	if category == "block_fill_theme" or category == "block_fill_trail":
		refresh_equipment()
		queue_redraw()

func refresh_equipment() -> void:
	theme_id = SaveManager.get_equipped("block_fill_theme", "electric_cyan")
	trail_id = SaveManager.get_equipped("block_fill_trail", "sparkle")

func load_level(level_num: int) -> void:
	active_tiles.clear()
	path.clear()
	trail_sparks.clear()
	completion_burst.clear()
	is_animating_win = false
	win_anim_timer = 0.0
	is_dragging = false
	
	# Determine grid layout and difficulty
	_build_level_geometry(level_num)
	
	# Layout sizing: fit neatly centered in 360px width viewport
	var max_span = max(cols, rows)
	cell_size = clamp(310.0 / float(max_span), 36.0, 62.0)
	var total_w = cols * cell_size
	var total_h = rows * cell_size
	grid_origin = Vector2((360.0 - total_w) * 0.5, 120.0 + (360.0 - total_h) * 0.5)
	
	# Start with the initial tile filled
	if active_tiles.has(start_cell):
		path.append(start_cell)
	elif active_tiles.size() > 0:
		start_cell = active_tiles[0]
		path.append(start_cell)
		
	queue_redraw()

func _build_level_geometry(lvl: int) -> void:
	# Hand-crafted progressive geometry scaling to high difficulty:
	match lvl:
		1:
			cols = 4; rows = 4
			# Straightforward 4x4 C-shape
			for y in range(4):
				for x in range(4):
					if not (x in [1, 2] and y in [1, 2]):
						active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(0, 0)
		2:
			cols = 4; rows = 4
			# 4x4 Spiral
			for y in range(4):
				for x in range(4):
					if not (x == 2 and y == 1):
						active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(0, 0)
		3:
			cols = 5; rows = 5
			# 5x5 Ring with interior bottleneck
			for y in range(5):
				for x in range(5):
					if (x == 0 or x == 4 or y == 0 or y == 4 or (x == 2 and y in [1, 2, 3])):
						active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(0, 0)
		4:
			# Screenshot matching puzzle! (5x5 with 4-block bottom-right cutout)
			cols = 5; rows = 5
			for y in range(5):
				for x in range(5):
					# Exclude inner 2x2 block (x in [2, 3] and y in [2, 3])
					if not (x in [2, 3] and y in [2, 3]):
						active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(3, 2) # matches the circle start node in screenshot
		5:
			cols = 5; rows = 5
			# Full 5x5 snake grid (25 tiles)
			for y in range(5):
				for x in range(5):
					active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(0, 0)
		6:
			cols = 6; rows = 6
			# 6x6 Cross maze
			for y in range(6):
				for x in range(6):
					if not ((x in [0, 5] and y in [0, 5]) or (x in [2, 3] and y in [2, 3])):
						active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(1, 0)
		7:
			cols = 6; rows = 6
			# 6x6 S-Curve Bottlenecks
			for y in range(6):
				for x in range(6):
					if not (x == 2 and y in [1, 2, 3]) and not (x == 4 and y in [2, 3, 4]):
						active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(0, 0)
		8:
			cols = 6; rows = 6
			# Full 6x6 grid (36 tiles)
			for y in range(6):
				for x in range(6):
					active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(0, 0)
		9:
			cols = 7; rows = 7
			# 7x7 Castle / Moat
			for y in range(7):
				for x in range(7):
					if not (x in [2, 3, 4] and y in [2, 3, 4] and not (x == 3 and y == 2)):
						active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(0, 0)
		10:
			cols = 7; rows = 7
			# 7x7 Double Spiral
			for y in range(7):
				for x in range(7):
					if not (x in [1, 5] and y in [2, 3, 4]):
						active_tiles.append(Vector2i(x, y))
			start_cell = Vector2i(0, 0)
		_:
			# Procedural Master Scaled Levels (Levels 11 to 100+)
			_generate_procedural_hamiltonian_puzzle(lvl)

func _generate_procedural_hamiltonian_puzzle(lvl: int) -> void:
	# Size dynamically scales from 6x6 up to 8x8
	var s = clamp(5 + int(floor((lvl - 5) / 5.0)), 6, 8)
	cols = s
	rows = s
	
	# Generate a guaranteed solvable continuous single-line path via randomized DFS backtracker
	var visited: Dictionary = {}
	var gen_path: Array[Vector2i] = []
	var start = Vector2i(randi_range(0, cols - 1), randi_range(0, rows - 1))
	
	gen_path.append(start)
	visited[start] = true
	
	var cur = start
	var target_steps = int(cols * rows * randf_range(0.75, 0.95))
	
	var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for step in range(target_steps):
		dirs.shuffle()
		var moved = false
		for d in dirs:
			var nxt = cur + d
			if nxt.x >= 0 and nxt.x < cols and nxt.y >= 0 and nxt.y < rows:
				if not visited.has(nxt):
					visited[nxt] = true
					gen_path.append(nxt)
					cur = nxt
					moved = true
					break
		if not moved:
			break
			
	active_tiles = gen_path.duplicate()
	start_cell = gen_path[0]

func cell_to_screen(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)

func screen_to_cell(pos: Vector2) -> Vector2i:
	var local = pos - grid_origin
	var cx = int(floor(local.x / cell_size))
	var cy = int(floor(local.y / cell_size))
	return Vector2i(cx, cy)

func handle_touch_down(pos: Vector2) -> void:
	if is_animating_win:
		return
	is_dragging = true
	last_touch_pos = pos
	
	var cell = screen_to_cell(pos)
	if not active_tiles.has(cell):
		return
		
	# If path is empty, start from tapped cell
	if path.size() == 0:
		path.append(cell)
		_spawn_spark(pos)
		path_changed.emit()
		queue_redraw()
		return
		
	# If tapping the head of the path
	if cell == path.back():
		_spawn_spark(pos)
		return
		
	# If tapping previous tile in path, pop back
	if path.size() >= 2 and cell == path[path.size() - 2]:
		path.pop_back()
		path_changed.emit()
		queue_redraw()
		return
		
	# If tapping a tile earlier in path, rewind to that tile
	if path.has(cell):
		var idx = path.find(cell)
		path = path.slice(0, idx + 1)
		path_changed.emit()
		queue_redraw()
		return
		
	# If tapping an adjacent unvisited cell from head
	var head = path.back()
	if _is_orthogonal_adjacent(head, cell):
		path.append(cell)
		_spawn_spark(pos)
		path_changed.emit()
		_check_win_condition()
		queue_redraw()

func handle_touch_drag(pos: Vector2) -> void:
	if not is_dragging or is_animating_win:
		return
		
	# Interpolate between last_touch_pos and pos to catch all crossed cells during fast movement
	var dist = last_touch_pos.distance_to(pos)
	var steps = max(1, int(ceil(dist / (cell_size * 0.35))))
	for s in range(1, steps + 1):
		var sample_pos = last_touch_pos.lerp(pos, float(s) / float(steps))
		var cell = screen_to_cell(sample_pos)
		if active_tiles.has(cell):
			_try_step_to(cell, sample_pos)
			
	last_touch_pos = pos

func _try_step_to(cell: Vector2i, spark_pos: Vector2) -> void:
	if path.size() == 0:
		if active_tiles.has(cell):
			path.append(cell)
			path_changed.emit()
			queue_redraw()
		return
		
	var head = path.back()
	if cell == head:
		return
		
	# 1. Backtracking / Undo via dragging backward
	if path.size() >= 2 and cell == path[path.size() - 2]:
		path.pop_back()
		path_changed.emit()
		queue_redraw()
		return
		
	# 2. Stepping into unvisited orthogonal adjacent block
	if not path.has(cell) and _is_orthogonal_adjacent(head, cell):
		path.append(cell)
		_spawn_spark(spark_pos)
		path_changed.emit()
		_check_win_condition()
		queue_redraw()

func handle_touch_up() -> void:
	is_dragging = false
	queue_redraw()

func undo_step() -> void:
	if is_animating_win:
		return
	if path.size() > 1:
		path.pop_back()
		path_changed.emit()
		queue_redraw()

func reset_path() -> void:
	if is_animating_win:
		return
	path.clear()
	if active_tiles.has(start_cell):
		path.append(start_cell)
	path_changed.emit()
	queue_redraw()

func _is_orthogonal_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var diff = a - b
	return (abs(diff.x) == 1 and diff.y == 0) or (abs(diff.y) == 1 and diff.x == 0)

func _check_win_condition() -> void:
	if path.size() == active_tiles.size():
		is_animating_win = true
		win_anim_timer = 0.0
		_spawn_win_burst()
		puzzle_completed.emit()

func _physics_process(delta: float) -> void:
	# Update Sparks
	for i in range(trail_sparks.size() - 1, -1, -1):
		var p = trail_sparks[i]
		p.pos += p.vel * delta
		p.life -= delta
		if p.life <= 0:
			trail_sparks.remove_at(i)
			
	# Update Win Burst
	for i in range(completion_burst.size() - 1, -1, -1):
		var b = completion_burst[i]
		b.pos += b.vel * delta
		b.vel.y += 120.0 * delta # slight gravity
		b.life -= delta
		if b.life <= 0:
			completion_burst.remove_at(i)
			
	if is_animating_win:
		win_anim_timer += delta
		
	queue_redraw()

func _spawn_spark(pos: Vector2) -> void:
	var col = _get_neon_color()
	for i in range(4):
		var ang = randf() * TAU
		var spd = randf_range(20.0, 70.0)
		trail_sparks.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"color": col.lightened(0.5),
			"size": randf_range(2.0, 4.5),
			"life": randf_range(0.2, 0.45)
		})

func _spawn_win_burst() -> void:
	for c in active_tiles:
		var pos = cell_to_screen(c)
		for i in range(6):
			var ang = randf() * TAU
			var spd = randf_range(60.0, 220.0)
			completion_burst.append({
				"pos": pos,
				"vel": Vector2(cos(ang), sin(ang)) * spd,
				"color": _get_neon_color(),
				"size": randf_range(3.0, 7.0),
				"life": randf_range(0.5, 0.9)
			})

func _get_neon_color() -> Color:
	match theme_id:
		"cyber_violet": return Color(0.85, 0.22, 0.98) # Magenta violet
		"emerald_matrix": return Color(0.18, 0.95, 0.45) # Neon matrix green
		"solar_amber": return Color(1.0, 0.72, 0.15) # Molten amber
		"rose_neon": return Color(0.98, 0.25, 0.55) # Rose quartz
		_: return Color(0.22, 0.82, 1.0) # Electric Cyan (Screenshot matching)

func _draw() -> void:
	var neon_col = _get_neon_color()
	var unvisited_col = Color(0.28, 0.28, 0.32) # Dark slate gray
	var unvisited_border = Color(0.18, 0.18, 0.22)
	
	var block_margin = cell_size * 0.08
	var block_size = cell_size - (block_margin * 2.0)
	var corner_radius = block_size * 0.22
	
	# 1. Draw Grid Tiles (Active blocks)
	for cell in active_tiles:
		var center = cell_to_screen(cell)
		var r = Rect2(center.x - block_size * 0.5, center.y - block_size * 0.5, block_size, block_size)
		var is_visited = path.has(cell)
		
		if is_visited:
			# Filled Glowing Neon Tile
			var tile_col = neon_col
			if is_animating_win:
				tile_col = tile_col.lightened(sin(win_anim_timer * 12.0) * 0.2)
			
			# Outer glow halo
			draw_rect(Rect2(r.position - Vector2(2, 2), r.size + Vector2(4, 4)), Color(tile_col.r, tile_col.g, tile_col.b, 0.25), true)
			# Main neon tile body
			_draw_rounded_rect(r, tile_col, corner_radius)
			# Top specular bevel highlight
			draw_line(Vector2(r.position.x + corner_radius, r.position.y + 2), Vector2(r.position.x + r.size.x - corner_radius, r.position.y + 2), tile_col.lightened(0.4), 1.8)
			
			# Inner concentric connection target circle (as seen on bottom row of screenshot)
			draw_arc(center, block_size * 0.22, 0, TAU, 16, Color(1, 1, 1, 0.35), 1.6)
		else:
			# Unvisited Slate Tile
			_draw_rounded_rect(r, unvisited_col, corner_radius)
			draw_rect(r, unvisited_border, false, 1.4)
			# Subtle top bevel
			draw_line(Vector2(r.position.x + corner_radius, r.position.y + 1), Vector2(r.position.x + r.size.x - corner_radius, r.position.y + 1), Color(0.42, 0.42, 0.46), 1.2)
			
	# 2. Draw Continuous Light-Tube Path
	if path.size() >= 2:
		for i in range(path.size() - 1):
			var p1 = cell_to_screen(path[i])
			var p2 = cell_to_screen(path[i + 1])
			
			# Outer tube glow
			draw_line(p1, p2, Color(1.0, 1.0, 1.0, 0.35), cell_size * 0.24)
			# Main solid cream-white connection tube
			draw_line(p1, p2, Color(0.98, 0.98, 0.94), cell_size * 0.14)
			# Central joint core
			draw_circle(p2, cell_size * 0.07, Color(0.98, 0.98, 0.94))
			
	# 3. Start Tile Ring Marker
	if path.size() > 0:
		var start_p = cell_to_screen(path[0])
		# Circle node outline matching screenshot
		draw_arc(start_p, cell_size * 0.18, 0, TAU, 18, Color(0.98, 0.98, 0.94), cell_size * 0.08)
		
	# 4. Active Finger / Path Head Spark Glow
	if path.size() > 0:
		var head_p = cell_to_screen(path.back())
		# Pulsing golden/white sunburst aura at finger tip
		var pulse = sin(Time.get_ticks_msec() * 0.008) * 3.0
		draw_circle(head_p, cell_size * 0.28 + pulse, Color(1.0, 0.88, 0.35, 0.4))
		draw_circle(head_p, cell_size * 0.14, Color(1.0, 1.0, 0.9))
		
	# 5. Draw Trail Sparks & Win Burst
	for s in trail_sparks:
		draw_circle(s.pos, s.size, s.color)
	for b in completion_burst:
		draw_circle(b.pos, b.size, b.color)

func _draw_rounded_rect(r: Rect2, col: Color, _radius: float) -> void:
	draw_rect(r, col, true)
