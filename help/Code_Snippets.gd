extends CharacterBody2D

func cleaner_input():
	var input_direction = Input.get_vector("KEY_LEFT", "KEY_RIGHT", "KEY_UP", "KEY_DOWN")


func rotating_player():
	var input_direction

	if input_direction.x < 0:
		rotation_degrees = 180
	elif input_direction.x > 0:
		rotation_degrees = 0
	elif input_direction.y < 0:
		rotation_degrees = 270
	elif input_direction.y > 0:
		rotation_degrees = 90



func sneak_system():
	var input_direction = 1
	var cur_speed = 150
	if Input.is_action_pressed("SNEAK"):
		cur_speed = 30
	
	velocity = input_direction * cur_speed



var CLOTHING_CHANE_SCRIPTS


func change():
	"""
	var not_worn_clothes = {}
	var list_empty = true
	for body in crowd:
		if body.clothes.value != cover_type:
			list_empty = false
			not_worn_clothes[body.clothes.value] = body.clothes
	if list_empty:
		return

	var random_clothing = randi_range(0, not_worn_clothes.keys().size() - 1)
	clothes_change(not_worn_clothes[not_worn_clothes.keys()[random_clothing]])
	"""




func cover_reset():
	"""
	cover_score = 0
	for body in crowd:
		if body.clothes.value == cover_type:
			cover_score += 1
	
	detection_change()
	"""

"""phycics_process():
	
get_input()
move_and_slide()

if Input.is_action_just_pressed("CLOTHES_CHANGE"):
	attempt_to_change_clothes()



"""






