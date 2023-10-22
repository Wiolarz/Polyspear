extends CharacterBody2D


@onready var clothes = $Sprite2D
@onready var crowd_area = $CrowdArea

@onready var police_area = $PoliceArea
#var 


@export var ui : RichTextLabel
var cover_type = 1

var crowd = []
var cover_score = 0

@export var speed = 150
@export var sneak_speed = 30
var a = 50

@export var detection_modifier = 20
var detection_range = 80



# Called when the node enters the scene tree for the first time.
func _ready():
	ui.text = "0"
	
	pass # Replace with function body.

func _draw():
	draw_circle_arc(get_position_delta(), $PoliceArea/CollisionShape2D.shape.radius, 0, 360, Color(1, 0, 0))
	# 

func draw_circle_arc(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PackedVector2Array()

	for i in range(nb_points + 1):
		var angle_point = deg_to_rad(angle_from + i * (angle_to-angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	for index_point in range(nb_points):
		draw_line(points_arc[index_point], points_arc[index_point + 1], color)


func detection_change():
	detection_range = max(0, 80 - (detection_modifier * cover_score))


func clothes_change(new_type):
	clothes.texture = new_type.player_version
	cover_type = new_type.value


func get_input():
	var input_direction = Input.get_vector("KEY_LEFT", "KEY_RIGHT", "KEY_UP", "KEY_DOWN")
	if input_direction.x < 0:
		rotation_degrees = 180
	elif input_direction.x > 0:
		rotation_degrees = 0
	elif input_direction.y < 0:
		rotation_degrees = 270
	elif input_direction.y > 0:
		rotation_degrees = 90
	
	
	
	var cur_speed = speed
	if Input.is_action_pressed("SNEAK"):
		cur_speed = sneak_speed
	
	velocity = input_direction * cur_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	get_input()
	move_and_slide()
	
	
	
	
	a += 1
	if a == 100:
		a = 0
	
	if detection_range > $PoliceArea/CollisionShape2D.shape.radius:
		$PoliceArea/CollisionShape2D.shape.radius += 1
	elif detection_range < $PoliceArea/CollisionShape2D.shape.radius:
		$PoliceArea/CollisionShape2D.shape.radius -= 1
		
		
	#print($PoliceArea/CollisionShape2D.shape.radius)
	queue_redraw()
	#print(crowd)



func _on_area_2d_area_entered(body):
	if not body.is_in_group("Humans"):
		return
	crowd.append(body)
	if body.clothes.value == cover_type:
		cover_score += 1
		ui.text = str(cover_score)
	detection_change()


func _on_area_2d_area_exited(body):
	if not body.is_in_group("Humans"):
		return
	crowd.erase(body)
	if body.clothes.value == cover_type:
		cover_score -= 1
		ui.text = str(cover_score)
	detection_change()


func _on_police_area_area_entered(body):
	if not body.is_in_group("Enemy"):
		return
		
	print("game over")
	


