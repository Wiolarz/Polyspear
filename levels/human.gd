extends Node2D

@export var follow_the_path = false

var path : Path2D

@export var clothes : clothes

var speed = 40

# Called when the node enters the scene tree for the first time.
func _ready():
	if follow_the_path:
		path = $Path2D
	$Sprite2D.texture = clothes.sprite



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if follow_the_path:
		path.get_path()
	
	var h_direction = 0.0
	var v_direction = 0
	position.x += speed * delta * h_direction

	position.y += speed * delta * v_direction
	
	if h_direction < 0:
		rotation_degrees = 180
	elif h_direction > 0:
		rotation_degrees = 0
	elif v_direction < 0:
		rotation_degrees = 270
	elif v_direction > 0:
		rotation_degrees = 90
