extends Control

# Splash screen that shows the title for a short duration then moves to Main Menu.

@onready var timer = Timer.new()

func _ready():
    add_child(timer)
    timer.wait_time = 2.0
    timer.one_shot = true
    timer.connect("timeout", Callable(self, "_on_timeout"))
    timer.start()

func _on_timeout():
    GameManager.go_to_main_menu()
