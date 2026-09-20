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
	register_game("hamster_game", {
		"title": "Hamster Game",
		"scene": "res://scenes/hamster_game/HamsterGame.tscn",
		"description": "Fast-paced 3x3 watch classic! Whack the cute hamsters before the 60s timer expires.",
		"high_score_key": "hamster_game",
		"status": "PLAYABLE"
	})
	register_game("block_fill", {
		"title": "Block Fill",
		"scene": "res://scenes/block_fill/BlockFill.tscn",
		"description": "Satisfying one-stroke puzzle! Fill every single block on the board with a continuous glowing neon line without overlapping.",
		"high_score_key": "block_fill",
		"status": "PLAYABLE"
	})

func register_game(id: String, info: Dictionary) -> void:
	games[id] = info

func get_game(id: String) -> Dictionary:
	return games.get(id, {})

func list_games() -> Array:
	return games.keys()

func get_customizer_data(game_id: String) -> Dictionary:
	match game_id:
		"snake":
			return {
				"title": "SNAKE UNLOCKS & ARENAS",
				"categories": [
					{
						"category_name": "SNAKES",
						"category_key": "snake_skin",
						"items": [
							{"id": "classic_green", "name": "Classic Green", "desc": "The timeless retro arcade serpent.", "req": "Starter"},
							{"id": "neon_viper", "name": "Neon Viper", "desc": "Glowing synthwave aesthetic.", "req": "Reach Score 10"},
							{"id": "desert_cobra", "name": "Desert Cobra", "desc": "Venomous golden scales.", "req": "Reach Score 35"},
							{"id": "cyber_dragon", "name": "Cyber Dragon", "desc": "Fiery crimson cyborg wyrm.", "req": "Reach Score 70"},
							{"id": "shadow_wyrm", "name": "Shadow Wyrm", "desc": "Mythic void cosmic dragon.", "req": "Reach Score 120"}
						]
					},
					{
						"category_name": "ARENAS",
						"category_key": "snake_arena",
						"items": [
							{"id": "classic_field", "name": "Classic Field", "desc": "Nostalgic green phosphor grid.", "req": "Starter"},
							{"id": "synthwave_grid", "name": "Synthwave Grid", "desc": "Cyberpunk neon battleground.", "req": "Reach Score 20"},
							{"id": "desert_dunes", "name": "Desert Dunes", "desc": "Warm sunlit desert arena.", "req": "Reach Score 50"},
							{"id": "frozen_tundra", "name": "Frozen Tundra", "desc": "Chilling glacial ice floor.", "req": "Reach Score 90"},
							{"id": "volcanic_abyss", "name": "Volcanic Abyss", "desc": "Infernal molten depths.", "req": "Reach Score 150"}
						]
					}
				]
			}
		"retro_racer":
			return {
				"title": "GARAGE & HIGHWAYS",
				"categories": [
					{
						"category_name": "VEHICLES",
						"category_key": "racer_vehicle",
						"items": [
							{"id": "red_racer", "name": "Red Racer", "desc": "Balanced sports coupe.", "req": "Starter"},
							{"id": "superbike", "name": "Superbike", "desc": "Nimble & lightning-fast steering.", "req": "Reach 300m"},
							{"id": "muscle_cruiser", "name": "Muscle Cruiser", "desc": "Heavy beast with chrome blower.", "req": "Reach 700m"},
							{"id": "turbo_bus", "name": "Turbo Bus", "desc": "Massive arcade city bus.", "req": "Reach 1200m"},
							{"id": "golden_f1", "name": "Golden F1", "desc": "Aerodynamic gold formula racer.", "req": "Reach 2000m"}
						]
					},
					{
						"category_name": "ROADS",
						"category_key": "racer_road",
						"items": [
							{"id": "city", "name": "City Asphalt", "desc": "Classic urban expressway.", "req": "Starter"},
							{"id": "cyber_neon", "name": "Cyber Neon", "desc": "Glowing midnight grid.", "req": "Reach 400m"},
							{"id": "desert", "name": "Desert Highway", "desc": "Sun-scorched canyon road.", "req": "Reach 900m"},
							{"id": "sunset_coast", "name": "Sunset Coast", "desc": "Neon twilight highway.", "req": "Reach 1500m"},
							{"id": "lava_gorge", "name": "Lava Gorge", "desc": "Infernal volcanic pass.", "req": "Reach 2500m"}
						]
					}
				]
			}
		"sky_hopper":
			return {
				"title": "BIRD ROSTER",
				"categories": [
					{
						"category_name": "BIRDS & FLYERS",
						"category_key": "hopper_bird",
						"items": [
							{"id": "yellow_finch", "name": "Yellow Finch", "desc": "Classic cheerful golden finch.", "req": "Starter"},
							{"id": "blue_falcon", "name": "Blue Falcon", "desc": "Supersonic raptor with cobalt wings.", "req": "Pass 10 Pipes"},
							{"id": "cyber_drone", "name": "Cyber Drone", "desc": "Hover drone with glowing scanner.", "req": "Pass 25 Pipes"},
							{"id": "pixel_phoenix", "name": "Pixel Phoenix", "desc": "Legendary firebird with ember crest.", "req": "Pass 50 Pipes"},
							{"id": "midnight_bat", "name": "Midnight Bat", "desc": "Nocturnal flyer with ruby eyes.", "req": "Pass 80 Pipes"}
						]
					}
				]
			}
		"bounce_quest":
			return {
				"title": "BOUNCE GEAR & GROUNDS",
				"categories": [
					{
						"category_name": "BALL SKINS",
						"category_key": "bounce_ball",
						"items": [
							{"id": "classic_red", "name": "Classic Red", "desc": "The iconic bouncy crimson sphere.", "req": "Starter"},
							{"id": "neon_pulse", "name": "Neon Pulse", "desc": "Glowing cyan energetic orb.", "req": "Clear Level 2"},
							{"id": "golden_orb", "name": "Golden Orb", "desc": "Gleaming celestial sphere of mastery.", "req": "Clear Level 4"}
						]
					},
					{
						"category_name": "GROUNDS",
						"category_key": "bounce_ground",
						"items": [
							{"id": "level_1", "name": "The Foothills", "desc": "Lush green rolling hills & ledges.", "req": "Starter"},
							{"id": "level_2", "name": "Spike Cavern", "desc": "Hazardous cavern with pit of spikes.", "req": "Clear Level 1"},
							{"id": "level_3", "name": "Floating Spires", "desc": "High altitude floating sky platforms.", "req": "Clear Level 2"},
							{"id": "level_4", "name": "Crystal Core", "desc": "Deep subterranean gem labyrinth.", "req": "Clear Level 3"},
							{"id": "level_5", "name": "Summit of Eternity", "desc": "Final celestial peak of mastery.", "req": "Clear Level 4"}
						]
					}
				]
			}
		"space_defender":
			return {
				"title": "SPACE HANGAR",
				"categories": [
					{
						"category_name": "STARSHIPS & JETS",
						"category_key": "space_jet",
						"items": [
							{"id": "starfighter", "name": "Starfighter", "desc": "Balanced twin-laser patrol craft.", "req": "Starter"},
							{"id": "interceptor", "name": "Interceptor", "desc": "High-speed 3-way spread shooter.", "req": "Clear Wave 3 / 1000 Pts"},
							{"id": "plasma_cruiser", "name": "Plasma Cruiser", "desc": "Heavy armored hull with 4 HP & plasma bolts.", "req": "Clear Wave 6 / 2500 Pts"},
							{"id": "phantom_bomber", "name": "Phantom Bomber", "desc": "Stealth fighter with rapid quad lasers.", "req": "Clear Wave 8 / 4500 Pts"},
							{"id": "golden_valkyrie", "name": "Golden Valkyrie", "desc": "God-tier golden flagship with 5 HP.", "req": "Defeat Boss / 7500 Pts"}
						]
					}
				]
			}
		"brick_breaker":
			return {
				"title": "BRICK GEAR & ARENAS",
				"categories": [
					{
						"category_name": "PADDLES",
						"category_key": "brick_paddle",
						"items": [
							{"id": "classic_cyan", "name": "Classic Cyan", "desc": "Balanced neon striker paddle.", "req": "Starter"},
							{"id": "plasma_blade", "name": "Plasma Blade", "desc": "Crimson blade with wide deflection.", "req": "Reach 600 Pts"},
							{"id": "golden_ingot", "name": "Golden Ingot", "desc": "Gilded auric bar with high bounce force.", "req": "Reach 1500 Pts"},
							{"id": "fire_striker", "name": "Fire Striker", "desc": "Blazing solar striker with rapid rebound.", "req": "Reach 3000 Pts"}
						]
					},
					{
						"category_name": "BALLS",
						"category_key": "brick_ball",
						"items": [
							{"id": "silver_sphere", "name": "Silver Sphere", "desc": "Polished chrome steel ball.", "req": "Starter"},
							{"id": "fireball_comet", "name": "Fireball Comet", "desc": "Flaming ember projectile.", "req": "Reach 1000 Pts"},
							{"id": "neon_prism", "name": "Neon Prism", "desc": "Prismatic crystal energy orb.", "req": "Reach 2200 Pts"}
						]
					},
					{
						"category_name": "ARENAS",
						"category_key": "brick_arena",
						"items": [
							{"id": "midnight_vault", "name": "Midnight Vault", "desc": "Dark indigo cyberpunk arena.", "req": "Starter"},
							{"id": "emerald_matrix", "name": "Emerald Matrix", "desc": "Phosphor green arcade grid.", "req": "Reach 800 Pts"},
							{"id": "crimson_chasm", "name": "Crimson Chasm", "desc": "Molten volcanic neon hall.", "req": "Reach 1800 Pts"}
						]
					}
				]
			}
		"hamster_game":
			return {
				"title": "BURROW ROSTER",
				"categories": [
					{
						"category_name": "PETS & ANIMALS",
						"category_key": "hamster_animal",
						"items": [
							{"id": "hamster", "name": "Golden Hamster", "desc": "Chubby cheeks & cute buck teeth.", "req": "Starter"},
							{"id": "bunny", "name": "Floppy Bunny", "desc": "Tall pink ears & twitchy nose.", "req": "Whack 20 Animals"},
							{"id": "kitty", "name": "Playful Kitty", "desc": "Pointed cat ears & cute whiskers.", "req": "Whack 50 Animals"},
							{"id": "panda", "name": "Sleepy Panda", "desc": "Black eye patches & round ears.", "req": "Whack 100 Animals"},
							{"id": "fox", "name": "Swift Kitsune", "desc": "Amber fur & black-tipped ears.", "req": "Whack 180 Animals"}
						]
					}
				]
			}
		"block_fill":
			return {
				"title": "NEON CUSTOMIZER",
				"categories": [
					{
						"category_name": "NEON PALETTES",
						"category_key": "block_fill_theme",
						"items": [
							{"id": "electric_cyan", "name": "Electric Cyan", "desc": "Classic intense fluorescent cyan blue glow.", "req": "Starter"},
							{"id": "cyber_violet", "name": "Cyber Violet", "desc": "Deep synthwave purple & magenta luminance.", "req": "Clear Level 5"},
							{"id": "emerald_matrix", "name": "Emerald Matrix", "desc": "High-tech terminal emerald green hue.", "req": "Clear Level 10"},
							{"id": "solar_amber", "name": "Solar Amber", "desc": "Radiant molten sunrise gold and orange.", "req": "Clear Level 15"},
							{"id": "rose_neon", "name": "Rose Quartz", "desc": "Vibrant hot pink and blossom aura.", "req": "Clear Level 25"}
						]
					},
					{
						"category_name": "TRAIL SPARKS",
						"category_key": "block_fill_trail",
						"items": [
							{"id": "sparkle", "name": "Starlight Sparks", "desc": "Twinkling golden starburst motes.", "req": "Starter"},
							{"id": "plasma_ring", "name": "Plasma Rings", "desc": "Pulsing concentric electric halos.", "req": "Clear Level 8"},
							{"id": "bubble_glow", "name": "Prism Bubbles", "desc": "Gentle floating chromatic orbs.", "req": "Clear Level 18"},
							{"id": "firefly", "name": "Cosmic Fireflies", "desc": "Drifting bioluminescent embers.", "req": "Clear Level 30"}
						]
					}
				]
			}
		_:
			return {"title": "CUSTOMIZE", "categories": []}
