extends Node

# SaveManager singleton handles persistent JSON save data for RETRORA.

const SAVE_PATH = "user://save_data.json"

var data: Dictionary = {
	"high_scores": {
		"snake": 0,
		"retro_racer": 0,
		"sky_hopper": 0,
		"bounce_quest": 0,
		"brick_breaker": 0,
		"space_defender": 0
	},
	"settings": {
		"sound": true,
		"music": true,
		"screen_shake": true,
		"vibration": true,
		"crt_filter": false
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
		"space_defender": 0
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
		"crt_filter": false
	}
	save_data()
