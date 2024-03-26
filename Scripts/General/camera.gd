extends Camera2D

func _process(_delta):
	
	if Input.is_action_just_pressed("KEY_ZOOM_OUT"):
		if zoom.x > 0.11: # float precision
			zoom.x -= 0.1
			zoom.y -= 0.1
		
	elif Input.is_action_just_pressed("KEY_ZOOM_IN"):
		if zoom.x < 1:
			zoom.x += 0.1
			zoom.y += 0.1

	var input_direction = Input.get_vector("KEY_LEFT", "KEY_RIGHT", "KEY_UP", "KEY_DOWN")
	if input_direction.x < 0:
		position.x -= 40
	elif input_direction.x > 0:
		position.x += 40

	if input_direction.y < 0:
		position.y -= 40
	elif input_direction.y > 0:
		position.y += 40