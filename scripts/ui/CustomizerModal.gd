extends Control

# CustomizerModal: In-game garage, skins, grounds & unlock selector for RETRORA games.

signal item_equipped(category_key: String, item_id: String)

var categories_data: Array = []
var active_category_idx: int = 0

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

func setup(title_text: String, categories: Array):
	modal_title.text = title_text
	categories_data = categories
	active_category_idx = 0
	_build_tabs()
	_populate_active_category()

func show_modal():
	get_tree().paused = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	modal_backdrop.visible = true
	_populate_active_category()

func hide_modal():
	get_tree().paused = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_backdrop.visible = false

func _build_tabs():
	for c in tabs_container.get_children():
		c.queue_free()

	for i in range(categories_data.size()):
		var cat = categories_data[i]
		var btn = Button.new()
		btn.text = cat.get("category_name", "CATEGORY")
		btn.custom_minimum_size = Vector2(100, 34)
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
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i] as Button
		if i == active_category_idx:
			btn.modulate = Color(0.3, 0.9, 1.0)
		else:
			btn.modulate = Color(0.7, 0.7, 0.7)

func _populate_active_category():
	for c in items_container.get_children():
		c.queue_free()

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
		card.custom_minimum_size = Vector2(280, 52)

		var hbox = HBoxContainer.new()
		hbox.theme_override_constants.separation = 8
		card.add_child(hbox)

		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text_vbox)

		var name_lbl = Label.new()
		name_lbl.text = item_name
		name_lbl.theme_override_font_sizes.font_size = 13
		if is_equipped:
			name_lbl.modulate = Color(0.3, 1.0, 0.5)
		elif is_unlocked:
			name_lbl.modulate = Color.WHITE
		else:
			name_lbl.modulate = Color(0.6, 0.6, 0.6)
		text_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = item_desc if is_unlocked else ("🔒 " + item_req)
		desc_lbl.theme_override_font_sizes.font_size = 10
		desc_lbl.modulate = Color(0.7, 0.7, 0.8) if is_unlocked else Color(1.0, 0.7, 0.3)
		text_vbox.add_child(desc_lbl)

		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(80, 36)
		action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		action_btn.focus_mode = Control.FOCUS_NONE

		if is_equipped:
			action_btn.text = "EQUIPPED"
			action_btn.disabled = true
			action_btn.modulate = Color(0.3, 1.0, 0.5)
		elif is_unlocked:
			action_btn.text = "EQUIP"
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
			action_btn.modulate = Color(0.5, 0.5, 0.5)

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
