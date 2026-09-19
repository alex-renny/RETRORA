extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready():
	layer = 128 # Always on top
	SettingsManager.crt_filter_toggled.connect(_on_crt_toggled)
	_on_crt_toggled(SettingsManager.crt_filter_enabled)

func _on_crt_toggled(enabled: bool):
	visible = enabled
