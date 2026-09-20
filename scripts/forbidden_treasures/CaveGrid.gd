extends Node2D

class_name CaveGrid

signal block_broken(cell: Vector2i, block_type: int)
signal treasure_collected(cell: Vector2i, item_name: String, value: int)
signal h2o_collected(amount: float)
signal player_crushed()
signal enemy_killed(enemy_pos: Vector2)
signal reached_exit()

# Tile Size
const CELL_SIZE: int = 24
const COLS: int = 15 # 15 * 24 = 360 px
var rows: int = 45

# Block Types
enum Block {
	EMPTY = 0,
	DIRT = 1,
	DENSE_ROCK = 2,
	BEDROCK = 3,
	BOULDER = 4,
	GOLD = 5,
	DIAMOND = 6,
	RELIC = 7,
	CHEST = 8,
	H2O = 9,
	TNT = 10,
	EXIT = 11
}

# Grid Storage
var grid: Dictionary = {}
var block_health: Dictionary = {}

# Biome configuration
var biome_name: String = "earth"
var current_level: int = 1

# Falling entities tracking
var falling_entities: Array[Dictionary] = []
var fall_check_timer: float = 0.0

# Enemies
var enemies: Array[Dictionary] = []

# Particles / Dig effects
var dig_particles: Array[Dictionary] = []

# Pre-seeded pseudo-random seed offsets for rock textures
var cell_noise_seeds: Dictionary = {}

func _ready() -> void:
	pass

func generate_level(level: int) -> void:
	current_level = level
	grid.clear()
	block_health.clear()
	falling_entities.clear()
	enemies.clear()
	dig_particles.clear()
	cell_noise_seeds.clear()
	
	if level <= 2:
		biome_name = "earth"
		rows = 40
	elif level <= 4:
		biome_name = "snow"
		rows = 50
	else:
		biome_name = "volcano"
		rows = 60
		
	# Fill grid
	for y in range(rows):
		for x in range(COLS):
			var cell = Vector2i(x, y)
			cell_noise_seeds[cell] = randi() % 1000
			
			# Bedrock boundaries (left & right borders, and bottom floor)
			if x == 0 or x == COLS - 1 or y == rows - 1:
				grid[cell] = Block.BEDROCK
				continue
				
			# Top rows 0, 1, 2, 3: Open surface sky above ground
			if y <= 3:
				grid[cell] = Block.EMPTY
				continue
				
			# Exit Portal at the bottom center
			if y == rows - 2 and (x == 7 or x == 8):
				grid[cell] = Block.EXIT
				continue
				
			# Spawn frequency matching the reference screenshot:
			var roll = randf()
			if roll < 0.05:
				grid[cell] = Block.BOULDER
			elif roll < 0.09:
				grid[cell] = Block.H2O
			elif roll < 0.16:
				grid[cell] = Block.GOLD
			elif roll < 0.20:
				grid[cell] = Block.DIAMOND
			elif roll < 0.22:
				grid[cell] = Block.CHEST
			elif roll < 0.24:
				grid[cell] = Block.RELIC
			elif roll < 0.26 or (biome_name == "volcano" and roll < 0.30):
				grid[cell] = Block.TNT
			elif roll < 0.38:
				grid[cell] = Block.DENSE_ROCK
				block_health[cell] = 2
			elif roll < 0.90:
				grid[cell] = Block.DIRT
				block_health[cell] = 1
			else:
				grid[cell] = Block.EMPTY
				
	# Clear entry mine shaft on row 4 for starting explorer
	grid[Vector2i(7, 4)] = Block.EMPTY
	grid[Vector2i(7, 5)] = Block.EMPTY
	
	# Spawn Biome Enemies in natural pockets
	var enemy_count = 2 + level
	for i in range(enemy_count):
		var test_y = randi_range(7, rows - 5)
		var test_x = randi_range(2, COLS - 3)
		grid[Vector2i(test_x - 1, test_y)] = Block.EMPTY
		grid[Vector2i(test_x, test_y)] = Block.EMPTY
		grid[Vector2i(test_x + 1, test_y)] = Block.EMPTY
		
		var enemy_type = "jackal"
		if biome_name == "snow": enemy_type = "frost_wolf"
		elif biome_name == "volcano": enemy_type = "fire_drake"
		
		enemies.append({
			"pos": cell_to_world(Vector2i(test_x, test_y)),
			"dir": 1 if randf() > 0.5 else -1,
			"speed": 36.0 + (level * 4.0),
			"patrol_min": (test_x - 2) * CELL_SIZE,
			"patrol_max": (test_x + 2) * CELL_SIZE,
			"row": test_y,
			"type": enemy_type,
			"anim_time": randf() * 10.0
		})
		
	queue_redraw()

func get_block(cell: Vector2i) -> int:
	return grid.get(cell, Block.BEDROCK)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)

func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / CELL_SIZE)), int(floor(pos.y / CELL_SIZE)))

func hit_block(cell: Vector2i, power: int) -> bool:
	if not grid.has(cell):
		return false
		
	var type = grid[cell]
	
	if type == Block.BEDROCK or type == Block.BOULDER:
		return false
		
	if type in [Block.GOLD, Block.DIAMOND, Block.RELIC, Block.CHEST, Block.H2O]:
		_collect_item(cell, type)
		grid[cell] = Block.EMPTY
		_spawn_debris(cell_to_world(cell), _get_item_color(type))
		queue_redraw()
		return true
		
	if type == Block.TNT:
		trigger_tnt_explosion(cell)
		return true
		
	if type == Block.DIRT or type == Block.DENSE_ROCK:
		var hp = block_health.get(cell, 1) - power
		_spawn_debris(cell_to_world(cell), _get_biome_ground_color())
		if hp <= 0:
			grid[cell] = Block.EMPTY
			block_health.erase(cell)
			block_broken.emit(cell, type)
			queue_redraw()
			return true
		else:
			block_health[cell] = hp
			queue_redraw()
			return false
			
	return false

func _collect_item(cell: Vector2i, type: int) -> void:
	match type:
		Block.GOLD:
			treasure_collected.emit(cell, "Gold Vein", 35 * current_level)
		Block.DIAMOND:
			treasure_collected.emit(cell, "Diamonds", 100 * current_level)
		Block.RELIC:
			treasure_collected.emit(cell, "Ancient Relic", 250 * current_level)
		Block.CHEST:
			treasure_collected.emit(cell, "Treasure Chest", 500 * current_level)
		Block.H2O:
			h2o_collected.emit(35.0)

func trigger_tnt_explosion(center_cell: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var c = center_cell + Vector2i(dx, dy)
			if grid.has(c) and grid[c] != Block.BEDROCK and grid[c] != Block.EXIT:
				if grid[c] in [Block.GOLD, Block.DIAMOND, Block.RELIC, Block.CHEST]:
					_collect_item(c, grid[c])
				grid[c] = Block.EMPTY
				block_health.erase(c)
				_spawn_debris(cell_to_world(c), Color(1.0, 0.45, 0.1))
	queue_redraw()

func _physics_process(delta: float) -> void:
	for i in range(dig_particles.size() - 1, -1, -1):
		var p = dig_particles[i]
		p.pos += p.vel * delta
		p.vel.y += 380.0 * delta
		p.life -= delta
		if p.life <= 0:
			dig_particles.remove_at(i)
			
	fall_check_timer += delta
	if fall_check_timer >= 0.12:
		fall_check_timer = 0.0
		_process_falling_physics()
		
	for e in enemies:
		e.anim_time += delta
		e.pos.x += e.dir * e.speed * delta
		if e.pos.x < e.patrol_min:
			e.pos.x = e.patrol_min
			e.dir = 1
		elif e.pos.x > e.patrol_max:
			e.pos.x = e.patrol_max
			e.dir = -1
			
	queue_redraw()

func _process_falling_physics() -> void:
	for y in range(rows - 2, 0, -1):
		for x in range(1, COLS - 1):
			var cell = Vector2i(x, y)
			var type = grid.get(cell, Block.EMPTY)
			if type == Block.BOULDER or type == Block.CHEST:
				var below = cell + Vector2i.DOWN
				if grid.get(below, Block.EMPTY) == Block.EMPTY:
					grid[below] = type
					grid[cell] = Block.EMPTY
					_spawn_debris(cell_to_world(below), Color(0.65, 0.65, 0.65))

func _spawn_debris(pos: Vector2, color: Color) -> void:
	for i in range(8):
		var angle = randf() * TAU
		var spd = randf_range(50.0, 160.0)
		dig_particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"color": color,
			"size": randf_range(2.0, 5.0),
			"life": randf_range(0.35, 0.65)
		})

func _get_biome_ground_color() -> Color:
	match biome_name:
		"snow": return Color(0.6, 0.78, 0.9)
		"volcano": return Color(0.28, 0.12, 0.08)
		_: return Color(0.55, 0.38, 0.2)

func _get_item_color(type: int) -> Color:
	match type:
		Block.GOLD: return Color(1.0, 0.85, 0.2)
		Block.DIAMOND: return Color(0.25, 0.9, 1.0)
		Block.RELIC: return Color(0.4, 1.0, 0.5)
		Block.CHEST: return Color(0.85, 0.65, 0.15)
		Block.H2O: return Color(0.15, 0.65, 1.0)
		_: return Color.WHITE

func _draw() -> void:
	# 1. Surface Mountain Sky Panorama (Rows 0 to 3)
	_draw_surface_sky_mountains()
	
	# 2. Underground Cavern Background (Deep Shaft Shadow)
	var underground_top = 4 * CELL_SIZE
	var total_height = rows * CELL_SIZE
	draw_rect(Rect2(0, underground_top, COLS * CELL_SIZE, total_height - underground_top), Color(0.06, 0.05, 0.10), true)
	
	# 3. Draw All Soil, Rock, Ore & Hazard Blocks
	for y in range(4, rows):
		for x in range(COLS):
			var cell = Vector2i(x, y)
			var type = grid.get(cell, Block.EMPTY)
			if type == Block.EMPTY:
				continue
			var rect = Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			_draw_realistic_cell(rect, type, cell)
			
	# 4. Draw Enemies
	_draw_enemies()
	
	# 5. Draw Debris & Spark Particles
	for p in dig_particles:
		draw_rect(Rect2(p.pos.x - p.size * 0.5, p.pos.y - p.size * 0.5, p.size, p.size), p.color, true)

func _draw_surface_sky_mountains() -> void:
	var w = COLS * CELL_SIZE
	var h = 4 * CELL_SIZE # 96px
	
	# Vivid Blue Sky Gradient
	draw_rect(Rect2(0, 0, w, h * 0.55), Color(0.08, 0.55, 0.88), true)
	draw_rect(Rect2(0, h * 0.55, w, h * 0.45), Color(0.4, 0.75, 0.95), true)
	
	# Majestic Snowy Mountain Range Silhouette (matching reference image)
	# Distant navy ridge
	var ridge1: PackedVector2Array = [
		Vector2(0, h),
		Vector2(0, 38),
		Vector2(45, 20),
		Vector2(95, 34),
		Vector2(145, 16),
		Vector2(200, 36),
		Vector2(260, 18),
		Vector2(310, 32),
		Vector2(w, 24),
		Vector2(w, h)
	]
	draw_polygon(ridge1, [Color(0.2, 0.35, 0.55)])
	
	# Snow caps and textured glacier faces
	var snow_peaks: PackedVector2Array = [
		Vector2(30, 26), Vector2(45, 20), Vector2(60, 28),
		Vector2(130, 22), Vector2(145, 16), Vector2(165, 25),
		Vector2(245, 24), Vector2(260, 18), Vector2(275, 26)
	]
	for i in range(0, snow_peaks.size(), 3):
		draw_polygon([snow_peaks[i], snow_peaks[i+1], snow_peaks[i+2]], [Color(0.95, 0.98, 1.0)])
		draw_line(snow_peaks[i+1], snow_peaks[i+1] + Vector2(2, 14), Color(0.9, 0.95, 1.0, 0.6), 2.5)

func _draw_realistic_cell(r: Rect2, type: int, cell: Vector2i) -> void:
	var c = r.get_center()
	var seed_val = cell_noise_seeds.get(cell, 0)
	
	match type:
		Block.BEDROCK:
			# Impenetrable Dark Granite Boundary
			draw_rect(r, Color(0.18, 0.18, 0.20), true)
			draw_rect(r, Color(0.1, 0.1, 0.12), false, 1.5)
			draw_line(r.position + Vector2(2, 2), r.position + Vector2(22, 22), Color(0.12, 0.12, 0.14), 1.5)
			
		Block.DIRT, Block.DENSE_ROCK:
			_draw_realistic_cobblestone_earth(r, type == Block.DENSE_ROCK, seed_val)
			
		Block.BOULDER:
			# Realistic 3D Textured Stone Boulder
			draw_circle(c + Vector2(0, 1), CELL_SIZE * 0.44, Color(0.0, 0.0, 0.0, 0.4)) # shadow
			draw_circle(c, CELL_SIZE * 0.44, Color(0.48, 0.50, 0.52)) # base granite
			draw_circle(c + Vector2(-2, -2), CELL_SIZE * 0.36, Color(0.62, 0.64, 0.68))
			# Surface pebble texture flecks
			draw_circle(c + Vector2(-3, 2), 1.6, Color(0.38, 0.4, 0.42))
			draw_circle(c + Vector2(3, -1), 1.8, Color(0.38, 0.4, 0.42))
			draw_circle(c + Vector2(-4, -4), CELL_SIZE * 0.14, Color(0.85, 0.88, 0.92)) # specular gleam
			
		Block.GOLD:
			# Ground with clustered sparkling gold flecks
			_draw_realistic_cobblestone_earth(r, false, seed_val)
			_draw_gold_nuggets(c, seed_val)
			
		Block.DIAMOND:
			# Ground with sparkling cyan diamond cluster (matching screenshot!)
			_draw_realistic_cobblestone_earth(r, false, seed_val)
			_draw_diamond_cluster(c)
			
		Block.CHEST:
			_draw_realistic_cobblestone_earth(r, false, seed_val)
			# Antique Reinforced Treasure Chest
			draw_rect(Rect2(c.x - 8, c.y - 6, 16, 12), Color(0.48, 0.28, 0.12), true)
			draw_rect(Rect2(c.x - 8, c.y - 6, 16, 3.5), Color(0.92, 0.78, 0.2), true)
			draw_rect(Rect2(c.x - 2, c.y - 1, 4, 5), Color(0.92, 0.78, 0.2), true)
			draw_circle(c + Vector2(0, 1.5), 1.2, Color(0.15, 0.1, 0.05))
			
		Block.RELIC:
			_draw_realistic_cobblestone_earth(r, false, seed_val)
			# Glowing Ancient Idol
			draw_circle(c + Vector2(0, -3), 4.2, Color(0.35, 0.95, 0.65))
			draw_rect(Rect2(c.x - 2.5, c.y - 1, 5, 8), Color(0.35, 0.95, 0.65), true)
			draw_line(c + Vector2(-6, 2), c + Vector2(6, 2), Color(0.35, 0.95, 0.65), 2.2)
			
		Block.H2O:
			_draw_realistic_cobblestone_earth(r, false, seed_val)
			# Nokia Classic Blue H2O Canister
			draw_rect(Rect2(c.x - 6, c.y - 4, 12, 12), Color(0.12, 0.58, 0.96), true)
			draw_rect(Rect2(c.x - 3, c.y - 8, 6, 4), Color(0.85, 0.92, 1.0), true)
			draw_rect(Rect2(c.x - 4, c.y - 2, 8, 6), Color(1.0, 1.0, 1.0, 0.55), true)
			
		Block.TNT:
			# Realistic Red Explosive Barrel with Warning Skull / Bomb (from screenshot)
			_draw_realistic_barrel(c)
			
		Block.EXIT:
			# Swirling Portal to next depth zone
			draw_rect(Rect2(c.x - 11, c.y - 11, 22, 22), Color(0.1, 0.08, 0.18), true)
			draw_arc(c, 9.0, 0, TAU, 18, Color(1.0, 0.85, 0.25), 3.0)
			draw_circle(c, 6.0, Color(0.3, 0.88, 1.0, 0.85))

func _draw_realistic_cobblestone_earth(r: Rect2, is_dense: bool, seed_val: int) -> void:
	# Realistic Packed Rocky Soil with organic cobblestones matching the reference screenshot!
	var base_brown = Color(0.52, 0.36, 0.18)
	var shadow_col = Color(0.24, 0.15, 0.07)
	var light_col = Color(0.70, 0.52, 0.32)
	
	if biome_name == "snow":
		base_brown = Color(0.55, 0.70, 0.85)
		shadow_col = Color(0.22, 0.35, 0.48)
		light_col = Color(0.82, 0.92, 1.0)
	elif biome_name == "volcano":
		base_brown = Color(0.25, 0.14, 0.10)
		shadow_col = Color(0.12, 0.05, 0.03)
		light_col = Color(0.48, 0.22, 0.12)
		
	if is_dense:
		base_brown = base_brown.darkened(0.25)
		shadow_col = shadow_col.darkened(0.3)
		
	# Fill base earthen cell
	draw_rect(r, base_brown, true)
	
	# Sub-divided cobblestone clusters (3 to 4 organic stones per cell)
	var p0 = r.position
	# Dark mortar groove outlines
	draw_rect(r, shadow_col, false, 1.2)
	
	# Internal stones with highlight rims and bottom drop-shadows
	var stone1 = Rect2(p0.x + 2, p0.y + 2, 9, 8)
	var stone2 = Rect2(p0.x + 13, p0.y + 2, 9, 9)
	var stone3 = Rect2(p0.x + 2, p0.y + 12, 10, 9)
	var stone4 = Rect2(p0.x + 14, p0.y + 13, 8, 8)
	
	for st in [stone1, stone2, stone3, stone4]:
		# Stone base
		draw_rect(st, base_brown.lightened(0.08), true)
		# Top highlight ridge
		draw_line(st.position, st.position + Vector2(st.size.x, 0), light_col, 1.2)
		# Bottom shadow ridge
		draw_line(st.position + Vector2(0, st.size.y), st.position + st.size, shadow_col, 1.4)
		
	# Dense rock adds cracked fissures
	if is_dense:
		draw_line(p0 + Vector2(4, 3), p0 + Vector2(19, 21), Color(0.08, 0.05, 0.03), 1.8)

func _draw_diamond_cluster(c: Vector2) -> void:
	# 3 Sparkling Multi-Faceted Diamonds in a triangle cluster (exact screenshot match!)
	var gem_offsets = [
		Vector2(-4, 3),
		Vector2(4, 3),
		Vector2(0, -4)
	]
	for off in gem_offsets:
		var gp = c + off
		# Diamond facet polygon
		var pts: PackedVector2Array = [
			gp + Vector2(0, -4.5),
			gp + Vector2(4.5, -0.5),
			gp + Vector2(0, 4.5),
			gp + Vector2(-4.5, -0.5)
		]
		draw_polygon(pts, [Color(0.18, 0.78, 0.98), Color(0.1, 0.55, 0.85), Color(0.45, 0.92, 1.0), Color(0.1, 0.55, 0.85)])
		# Top facet line
		draw_line(gp + Vector2(-4.5, -0.5), gp + Vector2(4.5, -0.5), Color(0.8, 0.98, 1.0), 1.0)
		# Gleam point
		draw_circle(gp + Vector2(0, -1.5), 1.2, Color.WHITE)

func _draw_gold_nuggets(c: Vector2, seed_val: int) -> void:
	# Natural scattered cluster of gleaming gold flecks
	var offsets = [
		Vector2(-5, -2), Vector2(-1, -5), Vector2(3, -2),
		Vector2(-2, 3), Vector2(4, 4)
	]
	for off in offsets:
		var gp = c + off
		draw_circle(gp, 1.8, Color(1.0, 0.82, 0.15))
		draw_circle(gp + Vector2(-0.5, -0.5), 0.8, Color(1.0, 0.98, 0.6))

func _draw_realistic_barrel(c: Vector2) -> void:
	# Wooden Barrel with metal hoop bands & bomb label
	var b_w = 15.0
	var b_h = 18.0
	var r = Rect2(c.x - b_w * 0.5, c.y - b_h * 0.5, b_w, b_h)
	
	# Wood Staves
	draw_rect(r, Color(0.72, 0.28, 0.15), true)
	# Steel Bands (top & bottom)
	draw_rect(Rect2(r.position.x, r.position.y + 2, b_w, 2.5), Color(0.35, 0.38, 0.42), true)
	draw_rect(Rect2(r.position.x, r.position.y + b_h - 4.5, b_w, 2.5), Color(0.35, 0.38, 0.42), true)
	# Center Warning Label
	draw_rect(Rect2(c.x - 4.5, c.y - 4.0, 9, 8), Color(0.95, 0.92, 0.8), true)
	# Bomb icon inside label
	draw_circle(c, 2.2, Color(0.15, 0.15, 0.15))
	draw_line(c + Vector2(1, -2), c + Vector2(3, -4), Color(0.7, 0.6, 0.2), 1.2)
	draw_circle(c + Vector2(3, -4), 1.0, Color(1.0, 0.3, 0.1)) # spark

func _draw_enemies() -> void:
	for e in enemies:
		var p = e.pos
		var bob = sin(e.anim_time * 8.0) * 2.0
		var type = e.type
		var d = e.dir
		
		match type:
			"jackal":
				var body_col = Color(0.72, 0.45, 0.22)
				draw_ellipse(p + Vector2(0, bob), 9.0, 6.0, body_col)
				draw_polygon([p + Vector2(d * 5, bob - 2), p + Vector2(d * 12, bob), p + Vector2(d * 5, bob + 4)], [body_col, body_col, body_col])
				draw_circle(p + Vector2(d * 4, bob - 3), 1.8, Color(1.0, 0.2, 0.2))
				draw_line(p + Vector2(-d * 2, bob - 5), p + Vector2(-d * 1, bob - 11), body_col, 2.5)
			"frost_wolf":
				var body_col = Color(0.85, 0.92, 0.98)
				draw_ellipse(p + Vector2(0, bob), 9.5, 6.5, body_col)
				draw_polygon([p + Vector2(d * 5, bob - 2), p + Vector2(d * 13, bob), p + Vector2(d * 5, bob + 4)], [body_col, body_col, body_col])
				draw_circle(p + Vector2(d * 4, bob - 3), 1.8, Color(0.2, 0.95, 1.0))
				draw_line(p + Vector2(-d * 4, bob - 5), p + Vector2(-d * 6, bob - 10), Color(0.4, 0.8, 1.0), 2.0)
			"fire_drake":
				var body_col = Color(0.85, 0.22, 0.12)
				draw_ellipse(p + Vector2(0, bob), 10.0, 6.0, body_col)
				draw_line(p + Vector2(-d * 2, bob - 4), p + Vector2(-d * 6, bob - 9), Color(0.2, 0.1, 0.1), 2.5)
				var flame_flicker = sin(e.anim_time * 15.0) * 3.0
				draw_circle(p + Vector2(-d * 10, bob + flame_flicker), 3.5, Color(1.0, 0.7, 0.1))
				draw_circle(p + Vector2(d * 4, bob - 2), 2.0, Color(1.0, 0.9, 0.2))
