extends Control

# Custom button drawing triangular wooden/brass arrows or detailed pickaxe

enum ButtonStyle {
	ARROW_LEFT,
	ARROW_RIGHT,
	PICKAXE
}

@export var style: ButtonStyle = ButtonStyle.ARROW_LEFT
var is_pressed: bool = false

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_pressed = event.pressed
		queue_redraw()
	elif event is InputEventScreenTouch:
		is_pressed = event.pressed
		queue_redraw()

func _draw() -> void:
	var r = Rect2(Vector2.ZERO, size)
	var press_offset = Vector2(0, 2) if is_pressed else Vector2.ZERO
	
	match style:
		ButtonStyle.ARROW_LEFT:
			_draw_triangle_button(r, -1.0, press_offset)
		ButtonStyle.ARROW_RIGHT:
			_draw_triangle_button(r, 1.0, press_offset)
		ButtonStyle.PICKAXE:
			_draw_pickaxe_button(r, press_offset)

func _draw_triangle_button(r: Rect2, dir: float, off: Vector2) -> void:
	# Outer Beveled Frame (brass/wood border exactly matching screenshot)
	var c = r.get_center() + off
	var w = r.size.x * 0.42
	var h = r.size.y * 0.44
	
	var pt_tip = c + Vector2(dir * w, 0)
	var pt_top = c + Vector2(-dir * w * 0.8, -h)
	var pt_bot = c + Vector2(-dir * w * 0.8, h)
	
	# Bevel Base (Drop shadow & outer bevel)
	var border_col = Color(0.72, 0.52, 0.28) # Brass gold rim
	var fill_col = Color(0.38, 0.24, 0.14) # Dark wood center
	if is_pressed:
		fill_col = fill_col.darkened(0.2)
		border_col = border_col.darkened(0.15)
		
	# Draw Outer Triangle
	draw_colored_polygon([pt_tip + Vector2(0, 3), pt_top + Vector2(0, 3), pt_bot + Vector2(0, 3)], Color(0, 0, 0, 0.4)) # shadow
	draw_colored_polygon([pt_tip, pt_top, pt_bot], border_col)
	
	# Draw Inner Inset Triangle
	var inset_tip = c + Vector2(dir * (w - 4), 0)
	var inset_top = c + Vector2(-dir * (w * 0.8 - 4), -h + 5)
	var inset_bot = c + Vector2(-dir * (w * 0.8 - 4), h - 5)
	draw_colored_polygon([inset_tip, inset_top, inset_bot], fill_col)
	
	# Edge Highlights
	draw_line(pt_top, pt_tip, Color(0.95, 0.80, 0.45), 2.0)
	draw_line(pt_bot, pt_tip, Color(0.4, 0.25, 0.1), 2.0)

func _draw_pickaxe_button(r: Rect2, off: Vector2) -> void:
	var c = r.get_center() + off
	
	# Transparent circular glow touch-backing
	if is_pressed:
		draw_circle(c, r.size.x * 0.48, Color(1, 1, 1, 0.15))
		
	# Large Realistic Pickaxe matching bottom right of screenshot
	# Wooden haft
	var handle_base = c + Vector2(r.size.x * 0.32, r.size.y * 0.32)
	var handle_top = c + Vector2(-r.size.x * 0.18, -r.size.y * 0.18)
	
	# Wood grip texture lines
	draw_line(handle_base, handle_top, Color(0.76, 0.48, 0.32), 6.5)
	draw_line(handle_base, handle_top, Color(0.48, 0.25, 0.14), 1.5)
	
	# Metal head collar with copper rivet
	draw_circle(handle_top, 4.5, Color(0.85, 0.45, 0.25))
	
	# Curved Pickaxe Blade (Iron with chrome specular shine)
	var tip1 = handle_top + Vector2(-18, 16)
	var tip2 = handle_top + Vector2(16, -18)
	
	# Blade outline
	draw_line(tip1, tip2, Color(0.15, 0.15, 0.18), 7.0)
	# Steel core
	draw_line(tip1, tip2, Color(0.75, 0.78, 0.82), 5.0)
	# Chrome light gleam
	draw_line(tip1 + Vector2(2, -2), tip2 + Vector2(-2, 2), Color.WHITE, 1.8)
