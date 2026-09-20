extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var title_lbl: Label = $CenterContainer/VBoxContainer/Title
@onready var subtitle_lbl: Label = $CenterContainer/VBoxContainer/Subtitle

@onready var game_list: VBoxContainer = $CenterContainer/VBoxContainer/GameList
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton
@onready var customizer_modal: Control = $CustomizerModal

func _ready():
	back_button.pressed.connect(func(): GameManager.go_to_main_menu())
	SettingsManager.theme_changed.connect(func(_th): _refresh_theme())
	_refresh_theme()
	_populate_games()

func _refresh_theme():
	var pal = SettingsManager.get_palette()
	if color_rect:
		color_rect.color = pal["bg"]
	if title_lbl:
		title_lbl.modulate = pal["text_primary"]
	if subtitle_lbl:
		subtitle_lbl.modulate = pal["text_secondary"]

	if back_button:
		var b_style = StyleBoxFlat.new()
		b_style.set_corner_radius_all(8)
		b_style.bg_color = pal["card_bg"]
		b_style.border_color = pal["card_border"]
		b_style.set_border_width_all(1.5)
		back_button.add_theme_stylebox_override("normal", b_style)
		back_button.add_theme_color_override("font_color", pal["text_primary"])

func _populate_games():
	for child in game_list.get_children():
		child.queue_free()

	var pal = SettingsManager.get_palette()

	for game_id in GameRegistry.list_games():
		var info = GameRegistry.get_game(game_id)
		var high_score = SaveManager.get_high_score(info.get("high_score_key", game_id))
		var status = info.get("status", "")
		var gid = game_id
		var scene_path = info.get("scene", "")

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var play_btn = Button.new()
		if status == "PLAYABLE":
			play_btn.text = "%s  ▶  (BEST: %d)" % [info.get("title", game_id), high_score]
		else:
			play_btn.text = "%s  [COMING SOON]" % info.get("title", game_id)
			play_btn.disabled = true

		play_btn.custom_minimum_size = Vector2(230, 44)
		play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var p_style = StyleBoxFlat.new()
		p_style.set_corner_radius_all(8)
		p_style.content_margin_left = 12
		p_style.content_margin_right = 12
		p_style.bg_color = pal["card_bg"]
		p_style.border_color = pal["card_border"]
		p_style.set_border_width_all(1.5)
		play_btn.add_theme_stylebox_override("normal", p_style)
		play_btn.add_theme_color_override("font_color", pal["text_primary"])

		if status == "PLAYABLE":
			play_btn.pressed.connect(func(): 
				GameManager.selected_game_id = gid
				GameManager.change_scene(scene_path)
			)
		row.add_child(play_btn)

		if status == "PLAYABLE":
			var unlock_btn = Button.new()
			unlock_btn.text = "🎨"
			unlock_btn.tooltip_text = "View Skins, Grounds & Unlocks"
			unlock_btn.custom_minimum_size = Vector2(44, 44)
			
			var u_style = StyleBoxFlat.new()
			u_style.set_corner_radius_all(8)
			u_style.bg_color = pal["card_bg"]
			u_style.border_color = pal["accent_warning"]
			u_style.set_border_width_all(1.5)
			unlock_btn.add_theme_stylebox_override("normal", u_style)
			unlock_btn.modulate = pal["accent_warning"]

			unlock_btn.pressed.connect(func():
				var cdata = GameRegistry.get_customizer_data(gid)
				customizer_modal.setup(cdata.get("title", "UNLOCKS"), cdata.get("categories", []), "BACK TO SELECT")
				customizer_modal.show_modal()
			)
			row.add_child(unlock_btn)

		game_list.add_child(row)
