extends Node2D

const CRYSTAL_SCENE = preload("res://scenes/bounce_quest/Crystal.tscn")
const SPIKE_SCENE = preload("res://scenes/bounce_quest/Spikes.tscn")
const PORTAL_SCENE = preload("res://scenes/bounce_quest/Portal.tscn")
const LevelData = preload("res://scripts/bounce_quest/LevelData.gd")

var current_level_idx: int = 1
var score: int = 0
var lives: int = 3
var high_score: int = 0
var spawn_point: Vector2 = Vector2(60, 480)
var is_game_over: bool = false
var is_paused: bool = false

# Screen Shake
var shake_intensity: float = 0.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var platforms_container: Node2D = $Platforms
@onready var hazards_container: Node2D = $Hazards
@onready var crystals_container: Node2D = $Crystals
@onready var portals_container: Node2D = $Portals

# HUD Nodes
@onready var hud: CanvasLayer = $HUD
@onready var level_label: Label = $HUD/TopBar/LevelLabel
@onready var score_label: Label = $HUD/TopBar/ScoreLabel
@onready var lives_label: Label = $HUD/TopBar/LivesLabel
@onready var skin_button: Button = $HUD/TopBar/SkinButton
@onready var pause_button: Button = $HUD/TopBar/PauseButton
@onready var customizer_modal: Control = $HUD/CustomizerModal

# Dialogs
@onready var level_clear_panel: Control = $HUD/LevelClearPanel
@onready var level_clear_title: Label = $HUD/LevelClearPanel/VBox/Title
@onready var next_level_btn: Button = $HUD/LevelClearPanel/VBox/NextButton

@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var final_score_label: Label = $HUD/GameOverPanel/VBox/FinalScoreLabel
@onready var final_best_label: Label = $HUD/GameOverPanel/VBox/FinalBestLabel
@onready var retry_btn: Button = $HUD/GameOverPanel/VBox/BtnContainer/RetryButton
@onready var menu_btn: Button = $HUD/GameOverPanel/VBox/BtnContainer/MenuButton

# Touch Buttons
@onready var btn_left: Button = $HUD/TouchControls/LeftButton
@onready var btn_right: Button = $HUD/TouchControls/RightButton
@onready var btn_jump: Button = $HUD/TouchControls/JumpButton

func _ready():
	high_score = SaveManager.get_high_score("bounce_quest")
	player.died.connect(_on_player_died)

	SettingsManager.theme_changed.connect(func(_thm): _apply_theme())
	_apply_theme()

	_setup_customizer()
	var initial_ball = SaveManager.get_equipped("bounce_ball", "classic_red")
	player.apply_ball_skin(initial_ball)

	# Wire HUD controls
	if skin_button:
		skin_button.pressed.connect(func(): customizer_modal.show_modal())
	pause_button.pressed.connect(_toggle_pause)
	retry_btn.pressed.connect(restart_quest)
	menu_btn.pressed.connect(func(): GameManager.go_to_game_select())
	next_level_btn.pressed.connect(_load_next_level)

func _apply_theme():
	var p = SettingsManager.get_palette()
	level_label.add_theme_color_override("font_color", p["text_primary"])
	score_label.add_theme_color_override("font_color", p["text_accent"])
	lives_label.add_theme_color_override("font_color", p["accent_danger"])

	var top_bar = get_node_or_null("HUD/TopBar")
	if top_bar is Panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = p["card_bg"]
		sb.set_border_width_all(1)
		sb.border_color = p["card_border"]
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		top_bar.add_theme_stylebox_override("panel", sb)

	var btn_container = get_node_or_null("HUD/GameOverPanel/VBox/BtnContainer")
	if btn_container and not btn_container.has_node("UnlocksButton"):
		var u_btn = Button.new()
		u_btn.name = "UnlocksButton"
		u_btn.text = "🎨"
		u_btn.custom_minimum_size = Vector2(44, 40)
		u_btn.modulate = Color(1.0, 0.88, 0.25)
		u_btn.pressed.connect(func(): customizer_modal.show_modal())
		btn_container.add_child(u_btn)
		if btn_container.get_child_count() > 2:
			btn_container.move_child(u_btn, 1)

func _setup_customizer():
	if not customizer_modal:
		return
	var cdata = GameRegistry.get_customizer_data("bounce_quest")
	customizer_modal.setup(cdata.get("title", "BOUNCE GEAR & GROUNDS"), cdata.get("categories", []))
	customizer_modal.item_equipped.connect(func(cat_key, item_id):
		if cat_key == "bounce_ball":
			player.apply_ball_skin(item_id)
		elif cat_key == "bounce_ground":
			var lvl = 1
			match item_id:
				"level_1": lvl = 1
				"level_2": lvl = 2
				"level_3": lvl = 3
				"level_4": lvl = 4
				"level_5": lvl = 5
			load_level(lvl)
	)

	# Wire Touch buttons
	btn_left.button_down.connect(func(): player.set_move_dir(-1.0))
	btn_left.button_up.connect(func(): player.set_move_dir(0.0))
	btn_right.button_down.connect(func(): player.set_move_dir(1.0))
	btn_right.button_up.connect(func(): player.set_move_dir(0.0))
	btn_jump.button_down.connect(func(): player.set_high_bounce(true))
	btn_jump.button_up.connect(func(): player.set_high_bounce(false))

	restart_quest()

func restart_quest():
	score = 0
	lives = 3
	current_level_idx = 1
	is_game_over = false
	game_over_panel.visible = false
	level_clear_panel.visible = false
	load_level(current_level_idx)

func load_level(idx: int):
	current_level_idx = idx
	level_clear_panel.visible = false
	game_over_panel.visible = false

	# Clear previous level nodes
	for c in platforms_container.get_children(): c.queue_free()
	for c in hazards_container.get_children(): c.queue_free()
	for c in crystals_container.get_children(): c.queue_free()
	for c in portals_container.get_children(): c.queue_free()

	var data = LevelData.get_level(current_level_idx)
	spawn_point = data["spawn"]
	camera.limit_left = 0
	camera.limit_right = int(data["width"])
	camera.limit_bottom = 640
	camera.limit_top = -100

	# 1. Build Platforms
	var tile_tex = preload("res://assets/bounce_quest/platform_tile.png")
	for p_rect in data["platforms"]:
		var body = StaticBody2D.new()
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = p_rect.size
		col.shape = shape
		col.position = p_rect.size / 2.0
		body.position = p_rect.position
		body.add_child(col)

		# Visual NinePatchRect
		var np = NinePatchRect.new()
		np.texture = tile_tex
		np.size = p_rect.size
		np.patch_margin_left = 4
		np.patch_margin_top = 4
		np.patch_margin_right = 4
		np.patch_margin_bottom = 4
		np.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
		np.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
		body.add_child(np)

		platforms_container.add_child(body)

	# 2. Build Spikes
	for s_pos in data["spikes"]:
		var spike = SPIKE_SCENE.instantiate()
		spike.position = s_pos
		hazards_container.add_child(spike)

	# 3. Build Crystals
	for c_pos in data["crystals"]:
		var crystal = CRYSTAL_SCENE.instantiate()
		crystal.position = c_pos
		crystal.collected.connect(_on_crystal_collected)
		crystals_container.add_child(crystal)

	# 4. Build Exit Portal
	var portal = PORTAL_SCENE.instantiate()
	portal.position = data["portal"]
	portal.reached_goal.connect(_on_level_completed)
	portals_container.add_child(portal)

	# Reset player
	player.respawn_at(spawn_point)
	_update_hud()

func _update_hud():
	level_label.text = "LEVEL %d" % current_level_idx
	score_label.text = "SCORE: %d" % score
	var hearts = ""
	for i in range(lives):
		hearts += "♥ "
	lives_label.text = hearts.strip_edges()

func _process(delta: float):
	if is_game_over or is_paused:
		return

	# Smooth camera follow
	var target_cam_x = clamp(player.position.x, 180.0, camera.limit_right - 180.0)
	var target_cam_y = clamp(player.position.y - 40.0, 180.0, 320.0)
	camera.position = camera.position.lerp(Vector2(target_cam_x, target_cam_y), 8.0 * delta)

	# Camera Shake
	if shake_intensity > 0.0:
		shake_intensity = max(0.0, shake_intensity - 15.0 * delta)
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		camera.offset = Vector2.ZERO

func _on_crystal_collected(pts: int):
	score += pts
	_update_hud()

func _on_player_died():
	lives -= 1
	shake_intensity = 14.0
	_update_hud()

	if lives <= 0:
		_game_over()
	else:
		# Short delay then respawn
		await get_tree().create_timer(0.6).timeout
		player.respawn_at(spawn_point)

func _on_level_completed():
	score += 500
	_update_hud()

	if current_level_idx >= 1:
		SaveManager.unlock("bounce_ground", "level_2", "Level 2: Spike Cavern")
	if current_level_idx >= 2:
		SaveManager.unlock("bounce_ball", "neon_pulse", "Neon Pulse Ball")
		SaveManager.unlock("bounce_ground", "level_3", "Level 3: Floating Spires")
	if current_level_idx >= 3:
		SaveManager.unlock("bounce_ground", "level_4", "Level 4: Crystal Core")
	if current_level_idx >= 4:
		SaveManager.unlock("bounce_ball", "golden_orb", "Golden Orb Ball")
		SaveManager.unlock("bounce_ground", "level_5", "Level 5: Summit of Eternity")

	if current_level_idx >= 5:
		# Game Victory!
		level_clear_title.text = "QUEST COMPLETE!\nYOU CONQUERED ALL 5 LEVELS!"
		next_level_btn.text = "PLAY AGAIN"
		_save_high_score()
	else:
		level_clear_title.text = "LEVEL %d CLEARED!\n+500 BONUS" % current_level_idx
		next_level_btn.text = "NEXT LEVEL"

	level_clear_panel.visible = true

func _load_next_level():
	if current_level_idx >= 5:
		restart_quest()
	else:
		load_level(current_level_idx + 1)

func _game_over():
	is_game_over = true
	_save_high_score()

	final_score_label.text = "FINAL SCORE: %d" % score
	final_best_label.text = "BEST RECORD: %d" % high_score
	game_over_panel.visible = true

func _save_high_score():
	if score > high_score:
		high_score = score
		SaveManager.set_high_score("bounce_quest", high_score)

func _toggle_pause():
	if is_game_over:
		return
	var overlay = GameManager.open_pause_overlay($HUD)
	if overlay:
		is_paused = true
		player.is_active = false
		overlay.tree_exiting.connect(func():
			is_paused = false
			player.is_active = true
		)
