class_name LevelData

static func get_level(level_idx: int) -> Dictionary:
	match level_idx:
		1:
			return {
				"name": "Level 1: The Foothills",
				"spawn": Vector2(60, 480),
				"portal": Vector2(1080, 460),
				"width": 1200.0,
				"platforms": [
					# Main ground sections with gaps
					Rect2(0, 520, 360, 60),
					Rect2(440, 520, 320, 60),
					Rect2(840, 520, 360, 60),
					# Raised platforms to jump up
					Rect2(140, 420, 100, 20),
					Rect2(280, 360, 110, 20),
					Rect2(480, 420, 120, 20),
					Rect2(640, 360, 100, 20),
					Rect2(780, 420, 110, 20),
					Rect2(920, 360, 100, 20)
				],
				"spikes": [
					Vector2(370, 520),
					Vector2(390, 520),
					Vector2(410, 520),
					Vector2(770, 520),
					Vector2(790, 520),
					Vector2(810, 520)
				],
				"crystals": [
					Vector2(190, 380),
					Vector2(335, 320),
					Vector2(540, 380),
					Vector2(690, 320),
					Vector2(835, 380),
					Vector2(970, 320)
				]
			}
		2:
			return {
				"name": "Level 2: Spike Cavern",
				"spawn": Vector2(60, 480),
				"portal": Vector2(1120, 280),
				"width": 1250.0,
				"platforms": [
					# Start ledge
					Rect2(0, 520, 180, 60),
					# Stepping stones across spike lake
					Rect2(240, 480, 90, 20),
					Rect2(380, 420, 90, 20),
					Rect2(520, 360, 90, 20),
					Rect2(660, 420, 100, 20),
					Rect2(800, 480, 90, 20),
					# High exit ledge
					Rect2(940, 400, 90, 20),
					Rect2(1060, 340, 180, 40),
					# Floating middle rest
					Rect2(580, 260, 110, 20)
				],
				"spikes": [
					# Continuous floor spike hazard
					Vector2(200, 560), Vector2(230, 560), Vector2(260, 560),
					Vector2(320, 560), Vector2(360, 560), Vector2(400, 560),
					Vector2(440, 560), Vector2(480, 560), Vector2(520, 560),
					Vector2(560, 560), Vector2(600, 560), Vector2(640, 560),
					Vector2(700, 560), Vector2(740, 560), Vector2(780, 560),
					Vector2(840, 560), Vector2(880, 560), Vector2(920, 560),
					# Trap spikes on floating platform
					Vector2(670, 404),
					Vector2(810, 464)
				],
				"crystals": [
					Vector2(285, 440),
					Vector2(425, 380),
					Vector2(565, 320),
					Vector2(635, 220), # High risk crystal!
					Vector2(710, 380),
					Vector2(845, 440),
					Vector2(985, 360)
				]
			}
		3:
			return {
				"name": "Level 3: Sky Ruins",
				"spawn": Vector2(60, 500),
				"portal": Vector2(1180, 200),
				"width": 1300.0,
				"platforms": [
					# Bottom launch
					Rect2(0, 530, 160, 50),
					# Vertical staircase ascent
					Rect2(190, 460, 80, 20),
					Rect2(310, 400, 80, 20),
					Rect2(430, 340, 90, 20),
					Rect2(310, 260, 80, 20),
					Rect2(180, 200, 90, 20),
					# High bridge across the abyss
					Rect2(330, 170, 100, 20),
					Rect2(480, 170, 100, 20),
					Rect2(630, 170, 100, 20),
					# Descending pillars
					Rect2(770, 240, 80, 20),
					Rect2(890, 310, 80, 20),
					Rect2(1010, 380, 80, 20),
					# Final climb to victory altar
					Rect2(1130, 310, 80, 20),
					Rect2(1150, 240, 150, 30)
				],
				"spikes": [
					# Traps on the high bridge
					Vector2(380, 154),
					Vector2(530, 154),
					Vector2(680, 154),
					Vector2(890, 294),
					Vector2(1010, 364)
				],
				"crystals": [
					Vector2(230, 420),
					Vector2(350, 360),
					Vector2(475, 300),
					Vector2(225, 160),
					Vector2(430, 130),
					Vector2(580, 130),
					Vector2(810, 200),
					Vector2(930, 270),
					Vector2(1050, 340)
				]
			}
		_:
			return get_level(1)
