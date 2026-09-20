extends Control

const GAME_CARD := preload("res://scripts/ui/GameLibraryCard.gd")

@onready var color_rect: ColorRect = $ColorRect
@onready var title_lbl: Label = $MarginContainer/VBoxContainer/TopRow/HeaderCopy/Title
@onready var subtitle_lbl: Label = $MarginContainer/VBoxContainer/TopRow/HeaderCopy/Subtitle
@onready var game_grid: GridContainer = $MarginContainer/VBoxContainer/GameScroll/GameGrid
@onready var back_button: Button = $MarginContainer/VBoxContainer/TopRow/BackButton
@onready var customizer_modal: Control = $CustomizerModal

func _ready() -> void:
	back_button.pressed.connect(func(): GameManager.go_to_main_menu())
	SettingsManager.theme_changed.connect(func(_theme): _refresh_theme())
	_refresh_theme()
	_populate_games()

func _refresh_theme() -> void:
	var pal := SettingsManager.get_palette()
	color_rect.color = pal["bg"]
	title_lbl.add_theme_color_override("font_color", pal["text_primary"])
	subtitle_lbl.add_theme_color_override("font_color", pal["text_secondary"])

	var back_style := StyleBoxFlat.new()
	back_style.bg_color = pal["card_bg"]
	back_style.border_color = pal["card_border"]
	back_style.set_border_width_all(1)
	back_style.set_corner_radius_all(8)
	back_button.add_theme_stylebox_override("normal", back_style)
	back_button.add_theme_color_override("font_color", pal["text_primary"])

	for card in game_grid.get_children():
		card.refresh_theme(pal)

func _populate_games() -> void:
	for child in game_grid.get_children():
		child.queue_free()

	var game_ids := GameRegistry.list_games()
	game_ids.sort_custom(func(a, b): return GameRegistry.get_game(a).get("added_order", 0) > GameRegistry.get_game(b).get("added_order", 0))
	var pal := SettingsManager.get_palette()

	for index in game_ids.size():
		var game_id: String = game_ids[index]
		var info := GameRegistry.get_game(game_id)
		var card = GAME_CARD.new()
		card.setup(game_id, info, SaveManager.get_high_score(info.get("high_score_key", game_id)), false, pal)
		card.play_requested.connect(_play_game)
		card.customize_requested.connect(_show_customizer)
		game_grid.add_child(card)

func _play_game(game_id: String) -> void:
	var info := GameRegistry.get_game(game_id)
	if info.get("status", "") == "PLAYABLE":
		GameManager.selected_game_id = game_id
		GameManager.change_scene(info.get("scene", ""))

func _show_customizer(game_id: String) -> void:
	var cdata := GameRegistry.get_customizer_data(game_id)
	customizer_modal.setup(cdata.get("title", "UNLOCKS"), cdata.get("categories", []), "BACK TO LIBRARY")
	customizer_modal.show_modal()
