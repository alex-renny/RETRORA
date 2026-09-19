extends Control

@onready var score_list: VBoxContainer = $CenterContainer/VBoxContainer/ScoreList
@onready var total_label: Label = $CenterContainer/VBoxContainer/TotalScoreLabel
@onready var reset_btn: Button = $CenterContainer/VBoxContainer/ResetButton
@onready var back_btn: Button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	back_btn.pressed.connect(func(): GameManager.go_to_main_menu())
	reset_btn.pressed.connect(_on_reset_scores)
	_populate_scores()

func _populate_scores():
	for c in score_list.get_children():
		c.queue_free()

	var total = 0
	var games = [
		{"id": "snake", "title": "Snake", "unit": "pts"},
		{"id": "retro_racer", "title": "Retro Racer", "unit": "m"},
		{"id": "sky_hopper", "title": "Sky Hopper", "unit": "pts"},
		{"id": "bounce_quest", "title": "Bounce Quest", "unit": "pts"},
		{"id": "brick_breaker", "title": "Brick Breaker", "unit": "pts"},
		{"id": "space_defender", "title": "Space Defender", "unit": "pts"},
		{"id": "hamster_game", "title": "Hamster Game", "unit": "pts"}
	]

	for g in games:
		var sc = SaveManager.get_high_score(g["id"])
		total += sc

		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(280, 28)

		var name_lbl = Label.new()
		name_lbl.text = g["title"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var val_lbl = Label.new()
		val_lbl.text = "%d %s" % [sc, g["unit"]]
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.modulate = Color(1.0, 0.85, 0.2)
		row.add_child(val_lbl)

		score_list.add_child(row)

	total_label.text = "TOTAL ARCADE SCORE: %d" % total

func _on_reset_scores():
	SaveManager.reset_all_high_scores()
	_populate_scores()
