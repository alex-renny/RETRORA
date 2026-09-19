extends Node

# GameManager singleton handles scene transitions and common game flow.

var selected_game_id: String = ""

func _ready():
	pass

func change_scene(to_path: String) -> void:
	if ResourceLoader.exists(to_path):
		get_tree().change_scene_to_file(to_path)
	else:
		print("[GameManager] Warning: Scene file does not exist yet: ", to_path)

# Helper shortcuts for common scenes
func go_to_main_menu():
	change_scene("res://scenes/MainMenu.tscn")

func go_to_game_select():
	change_scene("res://scenes/GameSelect.tscn")

func go_to_settings():
	change_scene("res://scenes/Settings.tscn")

func go_to_high_scores():
	change_scene("res://scenes/HighScores.tscn")

func go_to_placeholder_game():
	change_scene("res://scenes/PlaceholderGame.tscn")

func go_to_pause_menu():
	change_scene("res://scenes/ui/PauseMenu.tscn")

func open_pause_overlay(target_parent: Node = null) -> Node:
	var existing = null
	if target_parent:
		existing = target_parent.get_node_or_null("PauseMenuOverlay")
	else:
		var current = get_tree().current_scene
		if current:
			existing = current.get_node_or_null("PauseMenuOverlay")
			target_parent = current

	if existing:
		get_tree().paused = false
		existing.queue_free()
		return null

	if target_parent:
		var pause_menu_scene = load("res://scenes/ui/PauseMenu.tscn")
		if pause_menu_scene:
			var pm = pause_menu_scene.instantiate()
			pm.name = "PauseMenuOverlay"
			target_parent.add_child(pm)
			get_tree().paused = true
			return pm
	go_to_pause_menu()
	return null

func go_to_sky_hopper():
	change_scene("res://scenes/sky_hopper/SkyHopper.tscn")

func go_to_bounce_quest():
	change_scene("res://scenes/bounce_quest/BounceQuest.tscn")

func go_to_retro_racer():
	change_scene("res://scenes/retro_racer/RetroRacer.tscn")

func go_to_space_defender():
	change_scene("res://scenes/space_defender/SpaceDefender.tscn")

func go_to_brick_breaker():
	change_scene("res://scenes/brick_breaker/BrickBreaker.tscn")

func go_to_hamster_game():
	change_scene("res://scenes/hamster_game/HamsterGame.tscn")
