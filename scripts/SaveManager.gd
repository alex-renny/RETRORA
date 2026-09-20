extends Node

# SaveManager singleton handles persistent JSON save data for RETRORA.

signal item_unlocked(category: String, item_id: String, item_name: String)
signal item_equipped(category: String, item_id: String)

const SAVE_PATH = "user://save_data.json"

var data: Dictionary = {
	"high_scores": {
		"snake": 0,
		"retro_racer": 0,
		"sky_hopper": 0,
		"bounce_quest": 0,
		"brick_breaker": 0,
		"space_defender": 0,
		"hamster_game": 0,
		"block_fill": 1
	},
	"settings": {
		"sound": true,
		"music": true,
		"screen_shake": true,
		"vibration": true,
		"crt_filter": false,
		"theme": "light"
	},
	"unlocks": {
		"snake_skin": ["classic_green"],
		"snake_arena": ["classic_field"],
		"racer_vehicle": ["red_racer"],
		"racer_road": ["city"],
		"hopper_bird": ["yellow_finch"],
		"bounce_ball": ["classic_red"],
		"space_jet": ["starfighter"],
		"brick_paddle": ["classic_cyan"],
		"brick_ball": ["silver_sphere"],
		"brick_arena": ["midnight_vault"],
		"hamster_animal": ["hamster"],
		"bounce_ground": ["level_1"],
		"block_fill_theme": ["electric_cyan"],
		"block_fill_trail": ["sparkle"]
	},
	"equipped": {
		"snake_skin": "classic_green",
		"snake_arena": "classic_field",
		"racer_vehicle": "red_racer",
		"racer_road": "city",
		"hopper_bird": "yellow_finch",
		"bounce_ball": "classic_red",
		"space_jet": "starfighter",
		"brick_paddle": "classic_cyan",
		"brick_ball": "silver_sphere",
		"brick_arena": "midnight_vault",
		"hamster_animal": "hamster",
		"bounce_ground": "level_1",
		"block_fill_theme": "electric_cyan",
		"block_fill_trail": "sparkle"
	}
}

func _ready():
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_data()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var txt = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary:
			if parsed.has("high_scores") and parsed["high_scores"] is Dictionary:
				for k in parsed["high_scores"]:
					data["high_scores"][k] = parsed["high_scores"][k]
			if parsed.has("settings") and parsed["settings"] is Dictionary:
				for k in parsed["settings"]:
					data["settings"][k] = parsed["settings"][k]
			if parsed.has("unlocks") and parsed["unlocks"] is Dictionary:
				for k in parsed["unlocks"]:
					data["unlocks"][k] = parsed["unlocks"][k]
			if parsed.has("equipped") and parsed["equipped"] is Dictionary:
				for k in parsed["equipped"]:
					data["equipped"][k] = parsed["equipped"][k]
			# Ensure starter items are always present
			var starter_defaults = {
				"snake_skin": "classic_green",
				"snake_arena": "classic_field",
				"racer_vehicle": "red_racer",
				"racer_road": "city",
				"hopper_bird": "yellow_finch",
				"bounce_ball": "classic_red",
				"space_jet": "starfighter",
				"brick_paddle": "classic_cyan",
				"brick_ball": "silver_sphere",
				"brick_arena": "midnight_vault",
				"hamster_animal": "hamster",
				"bounce_ground": "level_1"
			}
			for cat in starter_defaults:
				if not data["unlocks"].has(cat):
					data["unlocks"][cat] = [starter_defaults[cat]]
				elif not (starter_defaults[cat] in data["unlocks"][cat]):
					data["unlocks"][cat].append(starter_defaults[cat])
				if not data["equipped"].has(cat) or data["equipped"][cat] == "":
					data["equipped"][cat] = starter_defaults[cat]
		else:
			print("[SaveManager] Warning: corrupted save data, resetting to defaults.")
			save_data()
	else:
		save_data()

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

# --- High Scores ---

func set_high_score(game_id: String, score: int) -> void:
	if not data.has("high_scores"):
		data["high_scores"] = {}
	var current = data["high_scores"].get(game_id, 0)
	if score > current:
		data["high_scores"][game_id] = score
		save_data()

func get_high_score(game_id: String) -> int:
	if not data.has("high_scores"):
		data["high_scores"] = {}
	return data["high_scores"].get(game_id, 0)

func reset_all_high_scores() -> void:
	data["high_scores"] = {
		"snake": 0,
		"retro_racer": 0,
		"sky_hopper": 0,
		"bounce_quest": 0,
		"brick_breaker": 0,
		"space_defender": 0,
		"hamster_game": 0,
		"block_fill": 1
	}
	save_data()

# --- Settings ---

func get_setting(key: String, default_val = true):
	if not data.has("settings"):
		data["settings"] = {}
	return data["settings"].get(key, default_val)

func set_setting(key: String, val) -> void:
	if not data.has("settings"):
		data["settings"] = {}
	data["settings"][key] = val
	save_data()

func reset_all_settings() -> void:
	data["settings"] = {
		"sound": true,
		"music": true,
		"screen_shake": true,
		"vibration": true,
		"crt_filter": false,
		"theme": "light"
	}
	save_data()

# --- Progression & Unlocks ---

func is_unlocked(category: String, item_id: String) -> bool:
	if not data.has("unlocks") or not data["unlocks"].has(category):
		return false
	return item_id in data["unlocks"][category]

func unlock(category: String, item_id: String, item_name: String = "") -> bool:
	if not data.has("unlocks"):
		data["unlocks"] = {}
	if not data["unlocks"].has(category):
		data["unlocks"][category] = []
	if not (item_id in data["unlocks"][category]):
		data["unlocks"][category].append(item_id)
		save_data()
		var display_name = item_name if item_name != "" else item_id.capitalize()
		item_unlocked.emit(category, item_id, display_name)
		return true
	return false

func get_equipped(category: String, default_id: String) -> String:
	if not data.has("equipped") or not data["equipped"].has(category):
		return default_id
	return data["equipped"].get(category, default_id)

func set_equipped(category: String, item_id: String) -> void:
	if not data.has("equipped"):
		data["equipped"] = {}
	data["equipped"][category] = item_id
	save_data()
	item_equipped.emit(category, item_id)
