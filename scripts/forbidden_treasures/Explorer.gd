extends Node2D

class_name Explorer

signal dug_block(grid_pos: Vector2i)
signal collected_item(item_type: String, value: int)
signal took_damage(amount: float)
signal player_died(reason: String)

var grid_pos: Vector2i = Vector2i(7, 4)
var target_world_pos: Vector2 = Vector2.ZERO
var move_speed: float = 12.0
var is_moving: bool = false
var facing_dir: Vector2i = Vector2i.DOWN

# Animation vars
var anim_time: float = 0.0
var walk_frame: float = 0.0
var is_digging: bool = false
var dig_timer: float = 0.0
var dig_duration: float = 0.22
var dig_target: Vector2i = Vector2i.ZERO
var blink_timer: float = 0.0
var is_blinking: bool = false

# Outfits and picks
var outfit_id: String = "adventurer"
var pick_id: String = "iron_pick"
var dig_power: int = 1

func _ready() -> void:
	refresh_equipment()
	target_world_pos = position
	SaveManager.item_equipped.connect(_on_item_equipped)

func _on_item_equipped(category: String, _item_id: String) -> void:
	if category == "treasure_outfit" or category == "treasure_pick":
		refresh_equipment()
		queue_redraw()

func refresh_equipment() -> void:
	outfit_id = SaveManager.get_equipped("treasure_outfit", "adventurer")
	pick_id = SaveManager.get_equipped("treasure_pick", "iron_pick")
		
	match pick_id:
		"iron_pick": dig_power = 1
		"diamond_mattock": dig_power = 2
		"magma_drill": dig_power = 2
		"celestial_pick": dig_power = 3
		_: dig_power = 1

func _process(delta: float) -> void:
	anim_time += delta
	
	# Blink handling
	blink_timer += delta
	if blink_timer >= 3.2:
		is_blinking = true
		if blink_timer >= 3.36:
			is_blinking = false
			blink_timer = 0.0
			
	# Movement interpolation
	if is_moving:
		walk_frame += delta * 16.0
		position = position.move_toward(target_world_pos, move_speed * 18.0 * delta * 60.0)
		if position.distance_to(target_world_pos) < 1.0:
			position = target_world_pos
			is_moving = false
			walk_frame = 0.0
	else:
		walk_frame = 0.0
		
	# Digging animation timer
	if is_digging:
		dig_timer -= delta
		if dig_timer <= 0:
			is_digging = false
			
	queue_redraw()

func start_move_to(new_grid_pos: Vector2i, new_world_pos: Vector2, dir: Vector2i) -> void:
	grid_pos = new_grid_pos
	target_world_pos = new_world_pos
	facing_dir = dir
	is_moving = true

func start_dig(dir: Vector2i, target_cell: Vector2i) -> void:
	facing_dir = dir
	is_digging = true
	dig_timer = dig_duration
	dig_target = target_cell

func _draw() -> void:
	# Realistic soft cast shadow on the ground
	draw_ellipse(Vector2(0, 11), 9, 4, Color(0, 0, 0, 0.45))
	
	# Walking bounce / breathing idle bob
	var bob: float = sin(walk_frame) * 2.2 if is_moving else sin(anim_time * 3.0) * 0.8
	var center = Vector2(0, -1 + bob)
	var flip = -1.0 if facing_dir == Vector2i.LEFT else 1.0
	
	# When digging or idle, miner holds pickaxe
	if is_digging:
		_draw_pickaxe_swing(center, flip)
	else:
		_draw_pickaxe_shoulder(center, flip)
		
	# Miner Body & Overalls
	_draw_miner_body(center, flip)
	
	# Miner Head, Face, Helmet & Headlamp
	_draw_miner_head(center, flip)

func _draw_miner_body(c: Vector2, flip: float) -> void:
	var pants_col = Color(0.18, 0.32, 0.72) # Classic blue overalls from screenshot
	var shirt_col = Color(0.92, 0.45, 0.22) # Red/orange work undershirt
	var boot_col = Color(0.12, 0.08, 0.05)
	
	match outfit_id:
		"mountaineer":
			pants_col = Color(0.2, 0.25, 0.35)
			shirt_col = Color(0.85, 0.2, 0.2)
		"obsidian_scavenger":
			pants_col = Color(0.15, 0.15, 0.18)
			shirt_col = Color(0.9, 0.4, 0.05)
		"golden_archaeologist":
			pants_col = Color(0.85, 0.7, 0.2)
			shirt_col = Color(0.95, 0.85, 0.3)
			
	# Legs with animated step
	var leg_swing = sin(walk_frame) * 4.0 if is_moving else 0.0
	# Left Leg & Boot
	draw_rect(Rect2(c.x - 5, c.y + 6 - leg_swing, 4.5, 6), pants_col, true)
	draw_rect(Rect2(c.x - 6, c.y + 11 - leg_swing, 5.5, 3), boot_col, true)
	
	# Right Leg & Boot
	draw_rect(Rect2(c.x + 1, c.y + 6 + leg_swing, 4.5, 6), pants_col, true)
	draw_rect(Rect2(c.x + 0.5, c.y + 11 + leg_swing, 5.5, 3), boot_col, true)
	
	# Torso & Blue Dungarees
	draw_rect(Rect2(c.x - 6, c.y - 1, 12, 8), pants_col, true)
	# Red/orange undershirt on arms/shoulders
	draw_rect(Rect2(c.x - 6.5, c.y - 2, 3, 4), shirt_col, true)
	draw_rect(Rect2(c.x + 3.5, c.y - 2, 3, 4), shirt_col, true)
	
	# Dungaree straps & brass buckles
	draw_rect(Rect2(c.x - 4.5, c.y - 1, 2.5, 7), pants_col.darkened(0.2), true)
	draw_rect(Rect2(c.x + 2.0, c.y - 1, 2.5, 7), pants_col.darkened(0.2), true)
	draw_circle(c + Vector2(-3.2, 1.5), 1.0, Color(0.9, 0.8, 0.3)) # buckle
	draw_circle(c + Vector2(3.2, 1.5), 1.0, Color(0.9, 0.8, 0.3))

func _draw_miner_head(c: Vector2, flip: float) -> void:
	var skin_col = Color(0.97, 0.78, 0.65)
	var head_c = c + Vector2(0, -7)
	
	# Neck
	draw_rect(Rect2(head_c.x - 2, head_c.y + 4, 4, 3), skin_col.darkened(0.1), true)
	
	# Head
	draw_circle(head_c, 5.8, skin_col)
	
	# Nose
	draw_circle(head_c + Vector2(flip * 3.8, 0.2), 1.4, skin_col.darkened(0.12))
	
	# Eye with blink & pupil
	var eye_x = head_c.x + (flip * 1.8)
	var eye_y = head_c.y - 0.5
	if is_blinking:
		draw_line(Vector2(eye_x - 1.5, eye_y), Vector2(eye_x + 1.5, eye_y), Color(0.2, 0.1, 0.05), 1.2)
	else:
		draw_circle(Vector2(eye_x, eye_y), 1.6, Color.WHITE)
		draw_circle(Vector2(eye_x + (flip * 0.4), eye_y), 0.9, Color(0.15, 0.15, 0.2))
		draw_circle(Vector2(eye_x + (flip * 0.2), eye_y - 0.4), 0.45, Color.WHITE) # catchlight
		
	# Moustache / Beard stubble
	draw_line(Vector2(head_c.x + (flip * 0.5), head_c.y + 2.2), Vector2(head_c.x + (flip * 3.5), head_c.y + 2.2), Color(0.4, 0.25, 0.15), 1.2)
	
	# Yellow Construction Miner Hard Hat
	var helmet_col = Color(0.96, 0.82, 0.18)
	if outfit_id == "mountaineer": helmet_col = Color(0.9, 0.25, 0.25)
	elif outfit_id == "obsidian_scavenger": helmet_col = Color(0.25, 0.28, 0.32)
	elif outfit_id == "golden_archaeologist": helmet_col = Color(1.0, 0.88, 0.25)
	
	# Hat Brim
	draw_ellipse(head_c + Vector2(0, -3), 7.8, 2.5, helmet_col.darkened(0.15))
	# Hat Dome
	draw_circle(head_c + Vector2(0, -4.5), 6.0, helmet_col)
	# Dome highlight ridge
	draw_arc(head_c + Vector2(0, -4.5), 5.2, -PI * 0.8, -PI * 0.2, 8, helmet_col.lightened(0.3), 1.5)
	
	# Front Mounted Headlamp with glowing light cone
	var lamp_c = head_c + Vector2(flip * 5.0, -4.5)
	draw_circle(lamp_c, 2.2, Color(0.4, 0.4, 0.45)) # lamp housing
	draw_circle(lamp_c, 1.4, Color(1.0, 1.0, 0.7)) # lit bulb
	# Subtle light bloom
	draw_circle(lamp_c, 3.5, Color(1.0, 0.95, 0.4, 0.25))

func _draw_pickaxe_shoulder(c: Vector2, flip: float) -> void:
	# Resting over the shoulder exactly like reference image
	var shoulder = c + Vector2(-flip * 3, -4)
	var handle_tip = shoulder + Vector2(-flip * 12, -10)
	var handle_butt = shoulder + Vector2(flip * 6, 4)
	
	var handle_col = Color(0.65, 0.42, 0.25)
	draw_line(handle_butt, handle_tip, handle_col, 2.4)
	
	# Pickaxe head resting over shoulder
	_draw_pick_head(handle_tip, -flip * 0.5)

func _draw_pickaxe_swing(c: Vector2, flip: float) -> void:
	var progress = 1.0 - (dig_timer / dig_duration)
	var swing_ang = sin(progress * PI) * 1.8
	
	var pivot = c + Vector2(flip * 4, -2)
	var dir_vec = Vector2(cos(swing_ang - 0.4), sin(swing_ang - 0.4))
	if flip < 0:
		dir_vec = Vector2(-cos(swing_ang - 0.4), sin(swing_ang - 0.4))
	if facing_dir == Vector2i.DOWN:
		dir_vec = Vector2(sin(swing_ang * 0.5), cos(swing_ang * 0.5))
		
	var handle_end = pivot + dir_vec * 16.0
	draw_line(pivot, handle_end, Color(0.65, 0.42, 0.25), 2.4)
	_draw_pick_head(handle_end, swing_ang)

func _draw_pick_head(pos: Vector2, angle: float) -> void:
	var head_col = Color(0.72, 0.75, 0.8) # Iron
	var gleam_col = Color(0.92, 0.95, 1.0)
	
	match pick_id:
		"diamond_mattock":
			head_col = Color(0.2, 0.85, 0.95)
			gleam_col = Color(0.85, 1.0, 1.0)
		"magma_drill":
			head_col = Color(0.95, 0.35, 0.1)
			gleam_col = Color(1.0, 0.8, 0.2)
		"celestial_pick":
			head_col = Color(1.0, 0.85, 0.2)
			gleam_col = Color(1.0, 1.0, 0.85)
			
	var perp = Vector2(-sin(angle), cos(angle)) * 7.5
	draw_line(pos - perp, pos + perp, head_col, 3.2)
	# Sharp pick points
	draw_circle(pos - perp, 1.5, gleam_col)
	draw_circle(pos + perp, 1.5, gleam_col)
	# Center mounting socket
	draw_circle(pos, 2.2, Color(0.3, 0.3, 0.35))
