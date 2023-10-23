"""

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



#at the start of phycics process
get_input()
move_and_slide()




"""
