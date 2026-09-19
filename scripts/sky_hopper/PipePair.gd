extends Node2D

signal passed_pipe
signal hit_player

var scroll_speed: float = 140.0
var passed: bool = false

@onready var top_pipe: Area2D = $TopPipe
@onready var bottom_pipe: Area2D = $BottomPipe
@onready var score_area: Area2D = $ScoreArea

func _ready():
	top_pipe.body_entered.connect(_on_pipe_body_entered)
	bottom_pipe.body_entered.connect(_on_pipe_body_entered)
	score_area.body_entered.connect(_on_score_area_entered)

func setup(gap_y: float, gap_height: float, speed: float):
	scroll_speed = speed

	var half_gap = gap_height / 2.0
	var top_y = gap_y - half_gap
	var bottom_y = gap_y + half_gap

	# Position Top Pipe (hangs down from above)
	top_pipe.position = Vector2(0.0, top_y)
	
	# Position Bottom Pipe (stands up from below)
	bottom_pipe.position = Vector2(0.0, bottom_y)

	# Position Score Trigger in the gap
	score_area.position = Vector2(24.0, gap_y)
	var col = score_area.get_node("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		col.shape.size = Vector2(20.0, gap_height)

func _process(delta: float):
	position.x -= scroll_speed * delta
	if position.x < -80.0:
		queue_free()

func _on_pipe_body_entered(body: Node2D):
	if body.is_in_group("player"):
		hit_player.emit()

func _on_score_area_entered(body: Node2D):
	if not passed and body.is_in_group("player"):
		passed = true
		passed_pipe.emit()
