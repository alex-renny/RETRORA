extends Node2D

const CaveGridScript = preload("res://scripts/forbidden_treasures/CaveGrid.gd")
const ExplorerScript = preload("res://scripts/forbidden_treasures/Explorer.gd")

@onready var camera: Camera2D = $Camera2D
@onready var cave_grid: Node2D = $CaveGrid
@onready var explorer: Node2D = $Explorer

# HUD nodes
@onready var hud: CanvasLayer = $HUD
@onready var total_cash_lbl: Label = $HUD/TopBar/TotalCashLabel
@onready var current_cash_lbl: Label = $HUD/TopBar/CurrentCashLabel
@onready var h2o_bar: ProgressBar = $HUD/TopBar/CenterHBox/H2OBar
@onready var pause_btn: Button = $HUD/TopBar/PauseButton
@onready var skin_btn: Button = $HUD/TopBar/SkinButton

# Reference Touch Controls
@onready var btn_left: Control = $HUD/TouchControls/LeftArrow
@onready var btn_right: Control = $HUD/TouchControls/RightArrow
@onready var btn_pick: Control = $HUD/TouchControls/PickaxeButton

# Popups & Modals
@onready var game_over_panel: PanelContainer = $HUD/GameOverPanel
@onready var game_over_reason: Label = $HUD/GameOverPanel/VBox/ReasonLabel
@onready var game_over_score: Label = $HUD/GameOverPanel/VBox/FinalScoreLabel
@onready var retry_btn: Button = $HUD/GameOverPanel/VBox/BtnContainer/RetryBtn
@onready var menu_btn: Button = $HUD/GameOverPanel/VBox/BtnContainer/MenuBtn

@onready var level_clear_panel: PanelContainer = $HUD/LevelClearPanel
@onready var level_clear_title: Label = $HUD/LevelClearPanel/VBox/ClearTitle
@onready var level_clear_bonus: Label = $HUD/LevelClearPanel/VBox/ClearBonus
@onready var next_level_btn: Button = $HUD/LevelClearPanel/VBox/NextLevelBtn

@onready var customizer_modal: Control = $HUD/CustomizerModal

# State
var current_level: int = 1
var current_cash: int = 0
var total_cash: int = 0
var h2o: float = 100.0
const MAX_H2O: float = 100.0
var h2o_depletion_normal: float = 2.4
var is_game_active: bool = false

# Movement
var hold_dir: Vector2i = Vector2i.ZERO
var input_cooldown: float = 0.0

func _ready() -> void:
	game_over_panel.visible = false
	level_clear_panel.visible = false
	customizer_modal.visible = false
	
	total_cash = SaveManager.get_high_score("forbidden_treasures")
	
	# Connect HUD signals
	pause_btn.pressed.connect(func(): GameManager.open_pause_overlay(hud))
	skin_btn.pressed.connect(_on_open_customizer)
	retry_btn.pressed.connect(restart_game)
	menu_btn.pressed.connect(func(): GameManager.go_to_game_select())
	next_level_btn.pressed.connect(_on_next_level_pressed)
	
	# Touch Buttons input connections
	btn_left.gui_input.connect(func(ev): _handle_dir_input(ev, Vector2i.LEFT))
	btn_right.gui_input.connect(func(ev): _handle_dir_input(ev, Vector2i.RIGHT))
	btn_pick.gui_input.connect(_handle_pick_input)
	
	# CaveGrid signals
	cave_grid.treasure_collected.connect(_on_treasure_collected)
	cave_grid.h2o_collected.connect(_on_h2o_collected)
	
	SettingsManager.theme_changed.connect(func(_th): _apply_theme())
	_apply_theme()
	
	start_level(1)

func _handle_dir_input(event: InputEvent, dir: Vector2i) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			hold_dir = dir
		elif hold_dir == dir:
			hold_dir = Vector2i.ZERO
	elif event is InputEventScreenTouch:
		if event.pressed:
			hold_dir = dir
		elif hold_dir == dir:
			hold_dir = Vector2i.ZERO

func _handle_pick_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		# Big pickaxe digs down or forward
		_try_dig_down_or_facing()

func _apply_theme() -> void:
	var pal = SettingsManager.get_palette()
	if total_cash_lbl: total_cash_lbl.modulate = pal["text_primary"]
	if current_cash_lbl: current_cash_lbl.modulate = pal["accent_warning"]

func start_level(lvl: int) -> void:
	current_level = lvl
	current_cash = 0
	h2o = MAX_H2O
	is_game_active = true
	game_over_panel.visible = false
	level_clear_panel.visible = false
	
	cave_grid.generate_level(current_level)
	
	var start_cell = Vector2i(7, 4)
	explorer.grid_pos = start_cell
	explorer.position = cave_grid.cell_to_world(start_cell)
	explorer.target_world_pos = explorer.position
	explorer.is_moving = false
	explorer.facing_dir = Vector2i.DOWN
	explorer.refresh_equipment()
	
	camera.position.x = 180
	camera.position.y = max(320.0, explorer.position.y)
	
	_update_hud()
	_check_unlock_milestones()

func _process(delta: float) -> void:
	if not is_game_active:
		return
		
	# H2O Depletion
	h2o -= h2o_depletion_normal * delta
	if h2o <= 0:
		h2o = 0
		_trigger_game_over("Out of Oxygen / H2O!")
		return
		
	h2o_bar.value = h2o
	
	# Handle continuous movement & digging
	input_cooldown -= delta
	if input_cooldown <= 0 and not explorer.is_moving:
		var dir = Vector2i.ZERO
		if Input.is_action_pressed("ui_left") or hold_dir == Vector2i.LEFT: dir = Vector2i.LEFT
		elif Input.is_action_pressed("ui_right") or hold_dir == Vector2i.RIGHT: dir = Vector2i.RIGHT
		elif Input.is_action_pressed("ui_down") or hold_dir == Vector2i.DOWN: dir = Vector2i.DOWN
		elif Input.is_action_pressed("ui_up") or hold_dir == Vector2i.UP: dir = Vector2i.UP
		
		if dir != Vector2i.ZERO:
			_attempt_step(dir)
			input_cooldown = 0.15
			
	if Input.is_action_just_pressed("ui_accept"):
		_try_dig_down_or_facing()
		
	# Smooth Camera Follow clamped to cave bounds
	var target_cam_y = clamp(explorer.position.y, 320.0, cave_grid.rows * CaveGridScript.CELL_SIZE - 320.0)
	camera.position.y = lerp(camera.position.y, target_cam_y, 7.5 * delta)
	
	_check_hazards()
	_update_hud()

func _attempt_step(dir: Vector2i) -> void:
	var next_cell = explorer.grid_pos + dir
	var block = cave_grid.get_block(next_cell)
	
	explorer.facing_dir = dir
	
	if block == CaveGridScript.Block.EXIT:
		_trigger_level_clear()
		return
		
	if block == CaveGridScript.Block.EMPTY:
		explorer.start_move_to(next_cell, cave_grid.cell_to_world(next_cell), dir)
	elif block in [CaveGridScript.Block.GOLD, CaveGridScript.Block.DIAMOND, CaveGridScript.Block.RELIC, CaveGridScript.Block.CHEST, CaveGridScript.Block.H2O]:
		cave_grid.hit_block(next_cell, explorer.dig_power)
		explorer.start_move_to(next_cell, cave_grid.cell_to_world(next_cell), dir)
	elif block in [CaveGridScript.Block.DIRT, CaveGridScript.Block.DENSE_ROCK]:
		_dig_cell(next_cell, dir)

func _try_dig_down_or_facing() -> void:
	# Prefer digging downward into the shaft if dirt exists below, otherwise facing direction
	var target_cell = explorer.grid_pos + Vector2i.DOWN
	var block_below = cave_grid.get_block(target_cell)
	if block_below in [CaveGridScript.Block.DIRT, CaveGridScript.Block.DENSE_ROCK, CaveGridScript.Block.GOLD, CaveGridScript.Block.DIAMOND, CaveGridScript.Block.RELIC, CaveGridScript.Block.CHEST, CaveGridScript.Block.H2O]:
		_dig_cell(target_cell, Vector2i.DOWN)
	else:
		var forward_cell = explorer.grid_pos + explorer.facing_dir
		_dig_cell(forward_cell, explorer.facing_dir)

func _dig_cell(cell: Vector2i, dir: Vector2i) -> void:
	var block = cave_grid.get_block(cell)
	if block == CaveGridScript.Block.BEDROCK:
		return
		
	explorer.start_dig(dir, cell)
	h2o = max(0, h2o - 0.7)
	var broke = cave_grid.hit_block(cell, explorer.dig_power)
	if broke and (hold_dir == dir or dir == Vector2i.DOWN):
		_attempt_step(dir)

func _check_hazards() -> void:
	var cur_block = cave_grid.get_block(explorer.grid_pos)
	if cur_block == CaveGridScript.Block.BOULDER:
		_trigger_game_over("Crushed by a falling boulder!")
		return
		
	for e in cave_grid.enemies:
		if explorer.position.distance_to(e.pos) < 16.0:
			_trigger_game_over("Ambushed by underground creatures!")
			return

func _on_treasure_collected(_cell: Vector2i, _item_name: String, val: int) -> void:
	current_cash += val
	total_cash += val
	_check_unlock_milestones()
	_update_hud()

func _on_h2o_collected(amount: float) -> void:
	h2o = min(MAX_H2O, h2o + amount)
	_update_hud()

func _check_unlock_milestones() -> void:
	if current_level >= 3:
		SaveManager.unlock("treasure_outfit", "mountaineer", "Arctic Mountaineer")
	if current_level >= 5:
		SaveManager.unlock("treasure_outfit", "obsidian_scavenger", "Obsidian Miner")
	if total_cash >= 5000:
		SaveManager.unlock("treasure_outfit", "golden_archaeologist", "Golden Legend")
		
	if total_cash >= 1000:
		SaveManager.unlock("treasure_pick", "diamond_mattock", "Diamond Mattock")
	if total_cash >= 2500:
		SaveManager.unlock("treasure_pick", "magma_drill", "Magma Drill")
	if total_cash >= 6000:
		SaveManager.unlock("treasure_pick", "celestial_pick", "Celestial Pickaxe")

func _update_hud() -> void:
	total_cash_lbl.text = "TOTAL $:\n%d" % total_cash
	current_cash_lbl.text = "CURRENT $:\n%d" % current_cash

func _trigger_level_clear() -> void:
	is_game_active = false
	var bonus = current_level * 500
	current_cash += bonus
	total_cash += bonus
	level_clear_title.text = "ZONE CLEARED!"
	level_clear_bonus.text = "Level Clear Bonus: +$%d\nTotal Expedition Wealth: $%d" % [bonus, total_cash]
	level_clear_panel.visible = true
	SaveManager.set_high_score("forbidden_treasures", total_cash)

func _on_next_level_pressed() -> void:
	start_level(current_level + 1)

func _trigger_game_over(reason: String) -> void:
	is_game_active = false
	game_over_reason.text = reason
	game_over_score.text = "TOTAL WEALTH: $%d" % total_cash
	game_over_panel.visible = true
	SaveManager.set_high_score("forbidden_treasures", total_cash)

func restart_game() -> void:
	current_cash = 0
	start_level(1)

func _on_open_customizer() -> void:
	var data = GameRegistry.get_customizer_data("forbidden_treasures")
	customizer_modal.open(data)
