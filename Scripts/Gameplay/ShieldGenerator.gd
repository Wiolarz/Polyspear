extends Node2D



func _process(_delta):
	if Input.is_action_just_pressed("KEY_POWER_SHIELD"):
		for shield in get_children():
			shield.active_state_change()


func _physics_process(_delta):
	look_at(get_global_mouse_position())
