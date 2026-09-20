extends Control

# CustomizerModal: In-game & menu garage, skins, grounds & unlock selector for RETRORA.

signal item_equipped(category_key: String, item_id: String)

const ItemPreviewScript = preload("res://scripts/ui/ItemPreview.gd")

var categories_data: Array = []
var active_category_idx: int = 0
var was_paused_before_open: bool = false

@onready var modal_backdrop: ColorRect = $ColorRect
@onready var modal_title: Label = $ColorRect/CenterContainer/VBox/Title
@onready var tabs_container: HBoxContainer = $ColorRect/CenterContainer/VBox/TabsContainer
@onready var scroll_container: ScrollContainer = $ColorRect/CenterContainer/VBox/ScrollContainer
@onready var items_container: VBoxContainer = $ColorRect/CenterContainer/VBox/ScrollContainer/ItemsContainer
@onready var close_btn: Button = $ColorRect/CenterContainer/VBox/CloseButton

# Floating unlock toast banner
@onready var unlock_toast: PanelContainer = $UnlockToast
@onready var toast_label: Label = $UnlockToast/ToastLabel

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if modal_backdrop:
		modal_backdrop.visible = false
	if unlock_toast:
		unlock_toast.visible = false
	if close_btn:
		close_btn.pressed.connect(hide_modal)
	SaveManager.item_unlocked.connect(_on_item_unlocked_globally)
	SettingsManager.theme_changed.connect(func(_th): _populate_active_category())

func setup(title_text: String, categories: Array, close_text: String = "BACK TO GAME"):
	modal_title.text = title_text
	categories_data = categories
	active_category_idx = 0
	if close_btn:
		close_btn.text = close_text
	_build_tabs()
	_populate_active_category()

func show_modal():
	was_paused_before_open = get_tree().paused
	get_tree().paused = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	modal_backdrop.visible = true
	_populate_active_category()

func hide_modal():
	get_tree().paused = was_paused_before_open
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_backdrop.visible = false

func _build_tabs():
	for c in tabs_container.get_children():
		c.queue_free()

	for i in range(categories_data.size()):
		var cat = categories_data[i]
		var btn = Button.new()
		btn.text = cat.get("category_name", "CATEGORY")
		btn.custom_minimum_size = Vector2(90, 32)
		var idx = i
		btn.pressed.connect(func():
			active_category_idx = idx
			_update_tab_styles()
			_populate_active_category()
		)
		tabs_container.add_child(btn)

	_update_tab_styles()

func _update_tab_styles():
	var tab_buttons = tabs_container.get_children()
	var pal = SettingsManager.get_palette()
	var is_light = SettingsManager.is_light_theme()

	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i] as Button
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 8

		if i == active_category_idx:
			style.bg_color = pal["text_accent"] if is_light else Color(0.2, 0.6, 0.9)
			btn.modulate = Color.WHITE
		else:
			style.bg_color = pal["card_border"]
			btn.modulate = pal["text_secondary"]

		btn.add_theme_stylebox_override("normal", style)

func _populate_active_category():
	for c in items_container.get_children():
		c.queue_free()

	var pal = SettingsManager.get_palette()
	var is_light = SettingsManager.is_light_theme()

	if modal_backdrop:
		modal_backdrop.color = pal["modal_bg"]
	if modal_title:
		modal_title.modulate = pal["text_primary"]

	if close_btn:
		var c_style = StyleBoxFlat.new()
		c_style.set_corner_radius_all(8)
		c_style.bg_color = pal["card_bg"]
		c_style.border_color = pal["card_border"]
		c_style.set_border_width_all(1.5)
		close_btn.add_theme_stylebox_override("normal", c_style)
		close_btn.add_theme_color_override("font_color", pal["text_primary"])

	_update_tab_styles()

	if categories_data.is_empty() or active_category_idx >= categories_data.size():
		return

	var cat = categories_data[active_category_idx]
	var cat_key = cat.get("category_key", "")
	var items = cat.get("items", [])
	var equipped_id = SaveManager.get_equipped(cat_key, items[0].get("id", "") if items.size() > 0 else "")

	for item in items:
		var item_id = item.get("id", "")
		var item_name = item.get("name", item_id)
		var item_desc = item.get("desc", "")
		var item_req = item.get("req", "")
		var is_unlocked = SaveManager.is_unlocked(cat_key, item_id)
		var is_equipped = (item_id == equipped_id)

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(308, 62)

		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 5
		style.content_margin_bottom = 5

		if is_light:
			if is_equipped:
				style.bg_color = Color(0.92, 0.98, 0.94, 0.95)
				style.border_color = pal["accent_success"]
				style.set_border_width_all(2)
			elif is_unlocked:
				style.bg_color = pal["card_bg"]
				style.border_color = pal["card_border"]
				style.set_border_width_all(1.5)
			else:
				style.bg_color = Color(0.97, 0.95, 0.92, 0.95)
				style.border_color = Color(0.85, 0.65, 0.3, 0.8)
				style.set_border_width_all(1)
		else:
			if is_equipped:
				style.bg_color = Color(0.06, 0.16, 0.09, 0.95)
				style.border_color = Color(0.25, 0.95, 0.5, 0.95)
				style.set_border_width_all(2)
			elif is_unlocked:
				style.bg_color = Color(0.08, 0.12, 0.18, 0.9)
				style.border_color = Color(0.25, 0.45, 0.65, 0.8)
				style.set_border_width_all(1)
			else:
				style.bg_color = Color(0.07, 0.05, 0.04, 0.92)
				style.border_color = Color(0.5, 0.35, 0.15, 0.75)
				style.set_border_width_all(1)

		card.add_theme_stylebox_override("panel", style)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		card.add_child(hbox)

		# 1. 50x50 Visual Vector Pixel Preview with lock overlay if locked
		var preview = ItemPreviewScript.new()
		preview.setup(cat_key, item_id, is_unlocked, is_equipped)
		hbox.add_child(preview)

		# 2. Text Content (Name, Description, Unlock Criteria Badge)
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		text_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(text_vbox)

		var name_lbl = Label.new()
		if is_equipped:
			name_lbl.text = "✓ " + item_name
			name_lbl.modulate = pal["accent_success"]
		elif is_unlocked:
			name_lbl.text = item_name
			name_lbl.modulate = pal["text_primary"]
		else:
			name_lbl.text = "🔒 " + item_name
			name_lbl.modulate = pal["text_secondary"]
		name_lbl.add_theme_font_size_override("font_size", 12)
		text_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = item_desc
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.modulate = pal["text_secondary"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_vbox.add_child(desc_lbl)

		if not is_unlocked:
			var req_lbl = Label.new()
			req_lbl.text = "CRITERIA: %s" % item_req
			req_lbl.add_theme_font_size_override("font_size", 9)
			req_lbl.modulate = pal["accent_warning"]
			req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_vbox.add_child(req_lbl)

		# 3. Action Button (EQUIPPED / EQUIP / LOCKED)
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(76, 36)
		action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		action_btn.focus_mode = Control.FOCUS_NONE

		if is_equipped:
			action_btn.text = "EQUIPPED"
			action_btn.disabled = true
			action_btn.modulate = pal["accent_success"]
		elif is_unlocked:
			action_btn.text = "EQUIP"
			action_btn.disabled = false
			action_btn.modulate = pal["accent_btn"]
			var cur_key = cat_key
			var cur_id = item_id
			action_btn.pressed.connect(func():
				SaveManager.set_equipped(cur_key, cur_id)
				item_equipped.emit(cur_key, cur_id)
				_populate_active_category()
			)
		else:
			action_btn.text = "LOCKED"
			action_btn.disabled = true
			action_btn.modulate = Color(0.55, 0.5, 0.45)

		hbox.add_child(action_btn)
		items_container.add_child(card)

func _on_item_unlocked_globally(_category: String, _item_id: String, item_name: String):
	show_toast("🎉 UNLOCKED: %s!" % item_name.to_upper())

func show_toast(text: String):
	if not unlock_toast or not toast_label:
		return
	toast_label.text = text
	unlock_toast.visible = true
	unlock_toast.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(unlock_toast, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): unlock_toast.visible = false)
