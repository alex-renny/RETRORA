extends Node2D

const BlockGridScript = preload("res://scripts/block_fill/BlockGrid.gd")

@onready var block_grid: Node2D = $BlockGrid

# HUD nodes
@onready var hud: CanvasLayer = $HUD
@onready var level_lbl: Label = $HUD/TopBar/LevelLabel
@onready var progress_lbl: Label = $HUD/TopBar/ProgressLabel
@onready var pause_btn: Button = $HUD/TopBar/PauseButton
@onready var skin_btn: Button = $HUD/TopBar/SkinButton

# Action Controls (Bottom)
@onready var undo_btn: Button = $HUD/BottomBar/UndoButton
@onready var reset_btn: Button = $HUD/BottomBar/ResetButton
@onready var tip_btn: Button = $HUD/BottomBar/TipButton

# Popups
@onready var level_clear_panel: PanelContainer = $HUD/LevelClearPanel
@onready var clear_title: Label = $HUD/LevelClearPanel/VBox/ClearTitle
@onready var next_btn: Button = $HUD/LevelClearPanel/VBox/NextButton

@onready var customizer_modal: Control = $HUD/CustomizerModal

# State
var current_level: int = 1
var highest_level: int = 1
var tip_cooldown_remaining: float = 0.0

func _ready() -> void:
	level_clear_panel.visible = false
	customizer_modal.visible = false
	
	highest_level = SaveManager.get_high_score("block_fill")
	if highest_level < 1:
		highest_level = 1
	current_level = highest_level
	
	# Connect buttons
	pause_btn.pressed.connect(func(): GameManager.open_pause_overlay(hud))
	skin_btn.pressed.connect(_on_open_customizer)
	undo_btn.pressed.connect(func(): block_grid.undo_step())
	reset_btn.pressed.connect(func(): block_grid.reset_path())
	tip_btn.pressed.connect(_on_tip_pressed)
	next_btn.pressed.connect(_on_next_level_pressed)
	
	# BlockGrid events
	block_grid.path_changed.connect(_update_progress_label)
	block_grid.puzzle_completed.connect(_on_level_completed)
	
	SettingsManager.theme_changed.connect(func(_th): _apply_theme())
	_apply_theme()
	
	start_level(current_level)

func _input(event: InputEvent) -> void:
	if customizer_modal.visible or level_clear_panel.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			block_grid.handle_touch_down(event.position)
		else:
			block_grid.handle_touch_up()
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			block_grid.handle_touch_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			block_grid.handle_touch_down(event.position)
		else:
			block_grid.handle_touch_up()
	elif event is InputEventScreenDrag:
		block_grid.handle_touch_drag(event.position)

func _apply_theme() -> void:
	var pal = SettingsManager.get_palette()
	if level_lbl: level_lbl.modulate = pal["text_primary"]
	if progress_lbl: progress_lbl.modulate = pal["accent_warning"]
	
	for b in [undo_btn, reset_btn, tip_btn]:
		if b:
			var s = StyleBoxFlat.new()
			s.bg_color = pal["card_bg"]
			s.border_color = pal["card_border"]
			s.set_border_width_all(1.5)
			s.set_corner_radius_all(10)
			b.add_theme_stylebox_override("normal", s)
			b.add_theme_color_override("font_color", pal["text_primary"])

func start_level(lvl: int) -> void:
	current_level = lvl
	level_clear_panel.visible = false
	
	block_grid.load_level(current_level)
	level_lbl.text = "LEVEL %d" % current_level
	_update_progress_label()
	_check_unlock_milestones()

func _process(delta: float) -> void:
	if tip_cooldown_remaining <= 0.0:
		return
	tip_cooldown_remaining = maxf(0.0, tip_cooldown_remaining - delta)
	_update_tip_button()

func _on_tip_pressed() -> void:
	if tip_cooldown_remaining > 0.0:
		return
	if block_grid.apply_hint():
		tip_cooldown_remaining = 60.0
		_update_tip_button()

func _update_tip_button() -> void:
	if tip_cooldown_remaining <= 0.0:
		tip_btn.disabled = false
		tip_btn.text = "💡 TIP"
	else:
		tip_btn.disabled = true
		tip_btn.text = "TIP %ds" % ceili(tip_cooldown_remaining)

func _update_progress_label() -> void:
	var filled = block_grid.path.size()
	var total = block_grid.active_tiles.size()
	progress_lbl.text = "%d / %d BLOCKS" % [filled, total]

func _on_level_completed() -> void:
	if current_level >= highest_level:
		highest_level = current_level + 1
		SaveManager.set_high_score("block_fill", highest_level)
		
	_check_unlock_milestones()
	
	# Delay popup by 0.6s so player sees full neon victory animation
	await get_tree().create_timer(0.6).timeout
	clear_title.text = "LEVEL %d COMPLETE!" % current_level
	level_clear_panel.visible = true

func _check_unlock_milestones() -> void:
	# Neon Color Themes
	if current_level >= 5:
		SaveManager.unlock("block_fill_theme", "cyber_violet", "Cyber Violet")
	if current_level >= 10:
		SaveManager.unlock("block_fill_theme", "emerald_matrix", "Emerald Matrix")
	if current_level >= 15:
		SaveManager.unlock("block_fill_theme", "solar_amber", "Solar Amber")
	if current_level >= 25:
		SaveManager.unlock("block_fill_theme", "rose_neon", "Rose Quartz")
		
	# Trail Sparks
	if current_level >= 8:
		SaveManager.unlock("block_fill_trail", "plasma_ring", "Plasma Rings")
	if current_level >= 18:
		SaveManager.unlock("block_fill_trail", "bubble_glow", "Prism Bubbles")
	if current_level >= 30:
		SaveManager.unlock("block_fill_trail", "firefly", "Cosmic Fireflies")

func _on_next_level_pressed() -> void:
	start_level(current_level + 1)

func _on_open_customizer() -> void:
	var data = GameRegistry.get_customizer_data("block_fill")
	customizer_modal.open(data)
