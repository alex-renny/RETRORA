extends CanvasLayer

signal steer_left_pressed
signal steer_right_pressed
signal boost_pressed(active: bool)
signal pause_pressed
signal retry_pressed
signal menu_pressed
signal theme_toggle_pressed

@onready var distance_label: Label = $HUD/TopBar/DistanceLabel
@onready var best_label: Label = $HUD/TopBar/BestLabel
@onready var boost_bar: ProgressBar = $HUD/BoostContainer/BoostBar
@onready var near_miss_label: Label = $HUD/NearMissLabel
@onready var game_over_panel: Control = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBox/FinalScoreLabel
@onready var final_best_label: Label = $GameOverPanel/VBox/FinalBestLabel
@onready var new_record_label: Label = $GameOverPanel/VBox/NewRecordLabel

var near_miss_timer: float = 0.0

func _ready():
	near_miss_label.visible = false
	game_over_panel.visible = false

	SettingsManager.theme_changed.connect(func(_thm): _apply_theme())
	_apply_theme()

	# Wire HUD buttons
	$HUD/TopBar/PauseButton.pressed.connect(func(): pause_pressed.emit())
	$HUD/TopBar/ThemeButton.pressed.connect(func():
		SettingsManager.toggle_theme()
		theme_toggle_pressed.emit()
	)
	
	# Wire Touch steer buttons
	$HUD/TouchControls/LeftButton.button_down.connect(func(): steer_left_pressed.emit())
	$HUD/TouchControls/RightButton.button_down.connect(func(): steer_right_pressed.emit())
	
	# Wire Boost button
	$HUD/TouchControls/BoostButton.button_down.connect(func(): boost_pressed.emit(true))
	$HUD/TouchControls/BoostButton.button_up.connect(func(): boost_pressed.emit(false))

	# Wire Game Over buttons
	$GameOverPanel/VBox/BtnContainer/RetryButton.pressed.connect(func(): retry_pressed.emit())
	$GameOverPanel/VBox/BtnContainer/MenuButton.pressed.connect(func(): menu_pressed.emit())

func _apply_theme():
	var p = SettingsManager.get_palette()
	distance_label.add_theme_color_override("font_color", p["text_primary"])
	best_label.add_theme_color_override("font_color", p["text_secondary"])

	var thm_btn = get_node_or_null("HUD/TopBar/ThemeButton")
	if thm_btn is Button:
		thm_btn.text = "☀️ LIGHT" if SettingsManager.is_light_theme() else "🌙 DARK"
		thm_btn.add_theme_color_override("font_color", p["text_accent"])

	var top_bar = get_node_or_null("HUD/TopBar")
	if top_bar is Panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = p["card_bg"]
		sb.set_border_width_all(1)
		sb.border_color = p["card_border"]
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		top_bar.add_theme_stylebox_override("panel", sb)

func _process(delta: float):
	if near_miss_timer > 0.0:
		near_miss_timer -= delta
		if near_miss_timer <= 0.0:
			near_miss_label.visible = false

func update_hud(distance: int, best: int, boost_ratio: float, speed_kmh: int):
	distance_label.text = "%05d m" % distance
	best_label.text = "BEST: %05d m" % best
	boost_bar.value = boost_ratio * 100.0

func show_near_miss():
	near_miss_label.visible = true
	near_miss_timer = 0.8

func show_game_over(final_dist: int, best_dist: int, is_new_record: bool):
	game_over_panel.visible = true
	final_score_label.text = "DISTANCE: %d m" % final_dist
	final_best_label.text = "BEST: %d m" % best_dist
	new_record_label.visible = is_new_record

func hide_game_over():
	game_over_panel.visible = false
