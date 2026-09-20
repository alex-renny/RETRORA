extends Node2D

const ENEMY_SCENE = preload("res://scenes/space_defender/Enemy.tscn")
const BOSS_SCENE = preload("res://scenes/space_defender/Boss.tscn")

var current_wave: int = 1
var max_waves: int = 10
var score: int = 0
var high_score: int = 0
var alive_enemies: int = 0
var is_boss_active: bool = false
var is_game_over: bool = false
var is_paused: bool = false
var is_wave_transitioning: bool = false

# Starfield data
var stars: Array = []

# Screen Shake
var shake_intensity: float = 0.0

@onready var player: Area2D = $Player
@onready var enemies_container: Node2D = $Enemies
@onready var camera: Camera2D = $Camera2D

# HUD Nodes
@onready var score_label: Label = $HUD/TopBar/ScoreLabel
@onready var wave_label: Label = $HUD/TopBar/WaveLabel
@onready var shields_label: Label = $HUD/TopBar/ShieldsLabel
@onready var hangar_button: Button = $HUD/TopBar/HangarButton
@onready var pause_button: Button = $HUD/TopBar/PauseButton
@onready var customizer_modal: Control = $HUD/CustomizerModal
@onready var banner_label: Label = $HUD/BannerLabel
@onready var boss_container: VBoxContainer = $HUD/BossContainer
@onready var boss_bar: ProgressBar = $HUD/BossContainer/BossBar

# Dialogs
@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var game_over_title: Label = $HUD/GameOverPanel/VBox/Title
@onready var final_score_label: Label = $HUD/GameOverPanel/VBox/FinalScoreLabel
@onready var final_best_label: Label = $HUD/GameOverPanel/VBox/FinalBestLabel
@onready var retry_btn: Button = $HUD/GameOverPanel/VBox/BtnContainer/RetryButton
@onready var menu_btn: Button = $HUD/GameOverPanel/VBox/BtnContainer/MenuButton

# Touch Buttons
@onready var btn_left: Button = $HUD/TouchControls/LeftButton
@onready var btn_right: Button = $HUD/TouchControls/RightButton
@onready var btn_up: Button = $HUD/TouchControls/UpButton
@onready var btn_down: Button = $HUD/TouchControls/DownButton
@onready var btn_fire: Button = $HUD/TouchControls/FireButton

var touch_vec: Vector2 = Vector2.ZERO

func _ready():
	high_score = SaveManager.get_high_score("space_defender")
	_init_starfield()

	SettingsManager.theme_changed.connect(func(_thm): _apply_theme())
	_apply_theme()

	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_player_health_changed)

	_setup_customizer()

	if hangar_button:
		hangar_button.pressed.connect(func(): customizer_modal.show_modal())
	pause_button.pressed.connect(_toggle_pause)
	retry_btn.pressed.connect(restart_game)
	menu_btn.pressed.connect(func(): GameManager.go_to_game_select())

func _apply_theme():
	var p = SettingsManager.get_palette()
	score_label.add_theme_color_override("font_color", p["text_primary"])
	wave_label.add_theme_color_override("font_color", p["text_accent"])
	shields_label.add_theme_color_override("font_color", p["accent_success"])

	var top_bar = get_node_or_null("HUD/TopBar")
	if top_bar is Panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = p["card_bg"]
		sb.set_border_width_all(1)
		sb.border_color = p["card_border"]
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		top_bar.add_theme_stylebox_override("panel", sb)
	queue_redraw()

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
	var cdata = GameRegistry.get_customizer_data("space_defender")
	customizer_modal.setup(cdata.get("title", "SPACE HANGAR"), cdata.get("categories", []))
	customizer_modal.item_equipped.connect(func(cat_key, item_id):
		if cat_key == "space_jet":
			player.apply_jet(item_id)
	)

	# Touch buttons wiring
	btn_left.button_down.connect(func(): touch_vec.x -= 1.0; _update_touch_vec())
	btn_left.button_up.connect(func(): touch_vec.x += 1.0; _update_touch_vec())
	btn_right.button_down.connect(func(): touch_vec.x += 1.0; _update_touch_vec())
	btn_right.button_up.connect(func(): touch_vec.x -= 1.0; _update_touch_vec())
	btn_up.button_down.connect(func(): touch_vec.y -= 1.0; _update_touch_vec())
	btn_up.button_up.connect(func(): touch_vec.y += 1.0; _update_touch_vec())
	btn_down.button_down.connect(func(): touch_vec.y += 1.0; _update_touch_vec())
	btn_down.button_up.connect(func(): touch_vec.y -= 1.0; _update_touch_vec())

	btn_fire.button_down.connect(func(): player.set_firing(true))

	restart_game()

func _init_starfield():
	stars.clear()
	for i in range(60):
		stars.append({
			"pos": Vector2(randf_range(0, 360), randf_range(0, 640)),
			"speed": randf_range(30, 150),
			"size": randi_range(1, 2),
			"color": Color(randf_range(0.6, 1.0), randf_range(0.7, 1.0), 1.0, randf_range(0.4, 0.9))
		})

func _update_touch_vec():
	player.set_move_vector(touch_vec)

func restart_game():
	score = 0
	current_wave = 1
	alive_enemies = 0
	is_boss_active = false
	is_game_over = false
	is_wave_transitioning = false
	game_over_panel.visible = false
	boss_container.visible = false

	# Clear containers
	for c in enemies_container.get_children(): c.queue_free()

	player.reset()
	_update_hud()
	_start_wave(current_wave)

func _start_wave(wave_idx: int):
	current_wave = wave_idx
	_update_hud()

	if current_wave > max_waves:
		# Trigger Boss Battle!
		_trigger_boss_wave()
		return

	is_wave_transitioning = true
	_show_banner("WAVE %d / %d" % [current_wave, max_waves], Color(0.3, 0.9, 1.0))
	await get_tree().create_timer(1.8).timeout
	is_wave_transitioning = false
	if is_game_over: return

	_spawn_wave_enemies(current_wave)

func _spawn_wave_enemies(w: int):
	var config = _get_wave_config(w)
	alive_enemies = config.size()

	for i in range(config.size()):
		var info = config[i]
		var enemy = ENEMY_SCENE.instantiate()
		enemies_container.add_child(enemy)
		var row = int(i / 5)
		var spawn_pos = Vector2(info["x"], -30.0 - (row * 48.0))
		enemy.setup(info["type"], spawn_pos, player)
		enemy.killed.connect(_on_enemy_killed)

func _get_wave_config(w: int) -> Array:
	var list: Array = []
	var count = 5 + w * 2

	for i in range(count):
		var x_pos = 45.0 + (i % 5) * 65.0
		var type = 0 # Basic
		if w >= 2 and i % 3 == 0:
			type = 1 # Fast
		if w >= 4 and i % 4 == 0:
			type = 2 # Tank
		if w >= 6 and i % 5 == 0:
			type = 3 # Shooter
		list.append({"type": type, "x": x_pos})

	return list

func _trigger_boss_wave():
	is_boss_active = true
	is_wave_transitioning = true
	wave_label.text = "BOSS WAVE"
	_show_banner("WARNING!\nMOTHERSHIP DETECTED", Color(1.0, 0.2, 0.2), 2.5)

	await get_tree().create_timer(2.5).timeout
	is_wave_transitioning = false
	if is_game_over: return

	boss_container.visible = true
	var boss = BOSS_SCENE.instantiate()
	enemies_container.add_child(boss)
	boss.start_battle(player)
	boss.health_changed.connect(_on_boss_health_changed)
	boss.boss_defeated.connect(_on_boss_defeated)

func _on_enemy_killed(pts: int):
	score += pts
	_update_hud()
	_check_unlock_milestones()
	alive_enemies = max(0, alive_enemies - 1)

	if alive_enemies <= 0 and not is_boss_active and not is_wave_transitioning:
		_on_wave_cleared()

func _on_wave_cleared():
	is_wave_transitioning = true
	score += 250 # Wave clear bonus
	_update_hud()
	_check_unlock_milestones()
	_show_banner("WAVE CLEARED! +250", Color(0.2, 1.0, 0.4), 1.5)
	await get_tree().create_timer(1.6).timeout
	is_wave_transitioning = false
	if not is_game_over:
		_start_wave(current_wave + 1)

func _check_unlock_milestones():
	if current_wave >= 3 or score >= 1000:
		SaveManager.unlock("space_jet", "interceptor", "Interceptor")
	if current_wave >= 6 or score >= 2500:
		SaveManager.unlock("space_jet", "plasma_cruiser", "Plasma Cruiser")
	if current_wave >= 8 or score >= 4500:
		SaveManager.unlock("space_jet", "phantom_bomber", "Phantom Bomber")
	if is_boss_active or score >= 7500:
		SaveManager.unlock("space_jet", "golden_valkyrie", "Golden Valkyrie")

func _on_boss_health_changed(current: int, total: int):
	boss_bar.max_value = total
	boss_bar.value = current

func _on_boss_defeated():
	score += 2500
	SaveManager.unlock("space_jet", "golden_valkyrie", "Golden Valkyrie")
	_save_high_score()
	_update_hud()
	shake_intensity = 20.0
	boss_container.visible = false

	_show_banner("VICTORY!\nGALAXY SAVED!", Color(1.0, 0.9, 0.2), 3.0)
	await get_tree().create_timer(3.0).timeout

	# Show Victory Screen
	game_over_title.text = "VICTORY!"
	final_score_label.text = "FINAL SCORE: %d" % score
	final_best_label.text = "BEST RECORD: %d" % high_score
	game_over_panel.visible = true

func _on_player_health_changed(new_hp: int):
	var shields = ""
	for i in range(new_hp):
		shields += "♥ "
	shields_label.text = shields.strip_edges()
	shake_intensity = 10.0

func _on_player_died():
	is_game_over = true
	shake_intensity = 18.0
	_save_high_score()

	game_over_title.text = "SHIP DESTROYED"
	final_score_label.text = "FINAL SCORE: %d" % score
	final_best_label.text = "BEST RECORD: %d" % high_score
	game_over_panel.visible = true

func _save_high_score():
	if score > high_score:
		high_score = score
		SaveManager.set_high_score("space_defender", high_score)

func _show_banner(text: String, col: Color, duration: float = 1.6):
	banner_label.text = text
	banner_label.modulate = col
	banner_label.visible = true
	var tween = create_tween()
	tween.tween_property(banner_label, "scale", Vector2(1.1, 1.1), duration * 0.5)
	tween.tween_property(banner_label, "scale", Vector2.ONE, duration * 0.5)
	tween.tween_callback(func(): banner_label.visible = false)

func _update_hud():
	score_label.text = "%05d" % score
	if not is_boss_active:
		wave_label.text = "WAVE %d/10" % current_wave

func _process(delta: float):
	# Starfield animation
	for s in stars:
		s["pos"].y += s["speed"] * delta
		if s["pos"].y > 640.0:
			s["pos"].y = 0.0
			s["pos"].x = randf_range(0, 360)
	queue_redraw()

	# Watchdog: ensure wave progression never gets stuck
	if not is_boss_active and not is_wave_transitioning and not is_game_over:
		if enemies_container.get_child_count() == 0 and alive_enemies > 0:
			alive_enemies = 0
			_on_wave_cleared()

	# Camera Shake
	if shake_intensity > 0.0:
		shake_intensity = max(0.0, shake_intensity - 18.0 * delta)
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		camera.offset = Vector2.ZERO

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

func _draw():
	var is_light = SettingsManager.is_light_theme()
	var bg_col = Color(0.12, 0.16, 0.24) if is_light else Color(0.03, 0.03, 0.06)
	draw_rect(Rect2(0, 0, 360, 640), bg_col)

	# Stars
	for s in stars:
		var star_col = s["color"]
		if is_light:
			star_col = Color(star_col.r, star_col.g, star_col.b, 0.9)
		draw_rect(Rect2(s["pos"], Vector2(s["size"], s["size"])), star_col)
