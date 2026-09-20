extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var title_lbl: Label = $CenterContainer/VBoxContainer/Title
@onready var score_list: VBoxContainer = $CenterContainer/VBoxContainer/ScoreList
@onready var total_label: Label = $CenterContainer/VBoxContainer/TotalScoreLabel
@onready var reset_btn: Button = $CenterContainer/VBoxContainer/ResetButton
@onready var back_btn: Button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	back_btn.pressed.connect(func(): GameManager.go_to_main_menu())
	reset_btn.pressed.connect(_on_reset_scores)
	SettingsManager.theme_changed.connect(func(_th): _apply_palette(); _populate_scores())
	_apply_palette()
	_populate_scores()

func _apply_palette():
	var pal = SettingsManager.get_palette()
	if color_rect:
		color_rect.color = pal["bg"]
	if title_lbl:
		title_lbl.modulate = pal["text_primary"]
	if total_label:
		total_label.modulate = pal["text_accent"]

	if back_btn:
		var b_style = StyleBoxFlat.new()
		b_style.set_corner_radius_all(8)
		b_style.bg_color = pal["card_bg"]
		b_style.border_color = pal["card_border"]
		b_style.set_border_width_all(1.5)
		back_btn.add_theme_stylebox_override("normal", b_style)
		back_btn.add_theme_color_override("font_color", pal["text_primary"])

func _populate_scores():
	for c in score_list.get_children():
		c.queue_free()

	var pal = SettingsManager.get_palette()
	var total = 0
	var games = [
		{"id": "snake", "title": "Snake", "unit": "pts"},
		{"id": "retro_racer", "title": "Retro Racer", "unit": "m"},
		{"id": "sky_hopper", "title": "Sky Hopper", "unit": "pts"},
		{"id": "bounce_quest", "title": "Bounce Quest", "unit": "pts"},
		{"id": "brick_breaker", "title": "Brick Breaker", "unit": "pts"},
		{"id": "space_defender", "title": "Space Defender", "unit": "pts"},
		{"id": "hamster_game", "title": "Hamster Game", "unit": "pts"},
		{"id": "forbidden_treasures", "title": "Forbidden Treasures", "unit": "$"},
		{"id": "block_fill", "title": "Block Fill", "unit": "lvl"}
	]

	for g in games:
		var sc = SaveManager.get_high_score(g["id"])
		total += sc

		var card = PanelContainer.new()
		var c_style = StyleBoxFlat.new()
		c_style.set_corner_radius_all(8)
		c_style.content_margin_left = 12
		c_style.content_margin_right = 12
		c_style.content_margin_top = 6
		c_style.content_margin_bottom = 6
		c_style.bg_color = pal["card_bg"]
		c_style.border_color = pal["card_border"]
		c_style.set_border_width_all(1.0)
		card.add_theme_stylebox_override("panel", c_style)

		var row = HBoxContainer.new()
		card.add_child(row)

		var name_lbl = Label.new()
		name_lbl.text = g["title"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.modulate = pal["text_primary"]
		name_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(name_lbl)

		var val_lbl = Label.new()
		val_lbl.text = "%d %s" % [sc, g["unit"]]
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.modulate = pal["accent_warning"]
		val_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(val_lbl)

		score_list.add_child(card)

	total_label.text = "TOTAL ARCADE SCORE: %d" % total

func _on_reset_scores():
	SaveManager.reset_all_high_scores()
	_populate_scores()
