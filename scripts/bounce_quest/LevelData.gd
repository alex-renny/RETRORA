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
		4:
			return {
				"name": "Level 4: Neon Gravity Lab",
				"spawn": Vector2(60, 480),
				"portal": Vector2(1360, 200),
				"width": 1450.0,
				"platforms": [
					# Entrance deck
					Rect2(0, 520, 160, 50),
					# Bouncy floating energy pads
					Rect2(210, 460, 75, 20),
					Rect2(330, 390, 75, 20),
					Rect2(450, 320, 75, 20),
					Rect2(580, 260, 90, 20),
					# Long high suspended gantry
					Rect2(720, 220, 140, 20),
					Rect2(910, 260, 80, 20),
					Rect2(1040, 330, 80, 20),
					# Stepping blocks over energy abyss
					Rect2(1170, 260, 80, 20),
					# Portal platform
					Rect2(1300, 240, 140, 30)
				],
				"spikes": [
					Vector2(250, 560), Vector2(300, 560), Vector2(350, 560),
					Vector2(400, 560), Vector2(450, 560), Vector2(500, 560),
					Vector2(600, 560), Vector2(700, 560), Vector2(800, 560),
					Vector2(900, 560), Vector2(1000, 560), Vector2(1100, 560),
					Vector2(780, 204), # Trap spike on the high gantry
					Vector2(1070, 314)
				],
				"crystals": [
					Vector2(245, 420),
					Vector2(365, 350),
					Vector2(485, 280),
					Vector2(625, 220),
					Vector2(750, 180),
					Vector2(830, 180),
					Vector2(950, 220),
					Vector2(1080, 290),
					Vector2(1210, 220)
				]
			}
		5:
			return {
				"name": "Level 5: Magma Citadel",
				"spawn": Vector2(60, 490),
				"portal": Vector2(1480, 160),
				"width": 1600.0,
				"platforms": [
					# Obsidian launchpad
					Rect2(0, 530, 150, 50),
					# Volcanic rock staircase
					Rect2(190, 470, 70, 20),
					Rect2(300, 410, 70, 20),
					Rect2(410, 350, 70, 20),
					Rect2(530, 290, 80, 20),
					# Precarious floating monoliths over lava chasm
					Rect2(660, 340, 70, 20),
					Rect2(780, 280, 70, 20),
					Rect2(900, 220, 80, 20),
					Rect2(1030, 280, 70, 20),
					Rect2(1150, 340, 70, 20),
					# High citadel wall ascent
					Rect2(1270, 280, 70, 20),
					Rect2(1370, 210, 70, 20),
					Rect2(1440, 190, 150, 30)
				],
				"spikes": [
					# Endless lava pit spikes below
					Vector2(200, 580), Vector2(250, 580), Vector2(300, 580),
					Vector2(350, 580), Vector2(400, 580), Vector2(450, 580),
					Vector2(500, 580), Vector2(550, 580), Vector2(600, 580),
					Vector2(650, 580), Vector2(700, 580), Vector2(750, 580),
					Vector2(800, 580), Vector2(850, 580), Vector2(900, 580),
					Vector2(950, 580), Vector2(1000, 580), Vector2(1050, 580),
					Vector2(1100, 580), Vector2(1150, 580), Vector2(1200, 580),
					Vector2(1250, 580), Vector2(1300, 580),
					# Monolith traps
					Vector2(560, 274),
					Vector2(930, 204),
					Vector2(1180, 324)
				],
				"crystals": [
					Vector2(225, 430),
					Vector2(335, 370),
					Vector2(445, 310),
					Vector2(570, 250),
					Vector2(695, 300),
					Vector2(815, 240),
					Vector2(940, 180),
					Vector2(1065, 240),
					Vector2(1185, 300),
					Vector2(1305, 240),
					Vector2(1405, 170)
				]
			}
		_:
			return get_level(1)
