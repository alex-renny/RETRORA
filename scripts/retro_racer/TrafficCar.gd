extends Area2D

signal near_miss(bonus: int)

var base_speed: float = 60.0
var car_speed: float = 0.0
var near_miss_checked: bool = false
var player_car_ref: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	add_to_group("traffic")

func setup(texture: Texture2D, speed_offset: float, player: Node2D):
	if sprite:
		sprite.texture = texture
	car_speed = base_speed + speed_offset
	player_car_ref = player

func _process(delta: float):
	# Traffic moves down relative to road scroll speed
	position.y += car_speed * delta

	# Near-miss check: when passing close to the player car without hitting
	if not near_miss_checked and player_car_ref and is_instance_valid(player_car_ref):
		var y_diff = abs(position.y - player_car_ref.position.y)
		var x_diff = abs(position.x - player_car_ref.position.x)
		
		# If vertical overlap occurs and horizontal clearance is close (lane next to player)
		if y_diff < 20.0:
			if x_diff > 22.0 and x_diff < 55.0:
				near_miss_checked = true
				near_miss.emit(50)

	if position.y > 680.0:
		queue_free()
