extends gun_turret



func _physics_process(_delta):
	look_at(get_global_mouse_position())


	if Input.is_action_pressed("KEY_SHOOT"):
		#print("shoot")
		super.shoot()
		
	#rotation = get_global_mouse_position().angle_to_point(global_position)
