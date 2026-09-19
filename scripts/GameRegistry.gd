extends Node

# GameRegistry singleton holds metadata for all 6 arcade games.

var games = {}

func _ready():
	register_game("snake", {
		"title": "Snake",
		"scene": "res://scenes/Snake.tscn",
		"description": "Grow your snake, collect food, and survive as long as possible.",
		"high_score_key": "snake",
		"status": "PLAYABLE"
	})
	register_game("sky_hopper", {
		"title": "Sky Hopper",
		"scene": "res://scenes/sky_hopper/SkyHopper.tscn",
		"description": "Navigate through endless obstacles and beat your high score.",
		"high_score_key": "sky_hopper",
		"status": "PLAYABLE"
	})
	register_game("bounce_quest", {
		"title": "Bounce Quest",
		"scene": "res://scenes/bounce_quest/BounceQuest.tscn",
		"description": "Explore retro platforms, collect crystals, and reach the goal.",
		"high_score_key": "bounce_quest",
		"status": "PLAYABLE"
	})
	register_game("brick_breaker", {
		"title": "Brick Breaker",
		"scene": "res://scenes/brick_breaker/BrickBreaker.tscn",
		"description": "Destroy every block with power-ups without losing the ball.",
		"high_score_key": "brick_breaker",
		"status": "PLAYABLE"
	})
	register_game("retro_racer", {
		"title": "Retro Racer",
		"scene": "res://scenes/retro_racer/RetroRacer.tscn",
		"description": "Survive the highway, weave through traffic, and boost your distance.",
		"high_score_key": "retro_racer",
		"status": "PLAYABLE"
	})
	register_game("space_defender", {
		"title": "Space Defender",
		"scene": "res://scenes/space_defender/SpaceDefender.tscn",
		"description": "Defend your ship against waves of enemies and epic bosses.",
		"high_score_key": "space_defender",
		"status": "PLAYABLE"
	})

func register_game(id: String, info: Dictionary) -> void:
	games[id] = info

func get_game(id: String) -> Dictionary:
	return games.get(id, {})

func list_games() -> Array:
	return games.keys()
