class_name PolyCamera
extends Camera2D

var last_mouse_position : Vector2
var target_zoom : Vector2 = Vector2(0.5, 0.5)
var bounds : Rect2 = Rect2(0,0,10000,10000)


func process_camera(_delta):
	if Input.is_action_just_pressed("KEY_ZOOM_OUT"):
		if target_zoom.x > 0.11: # float precision
			target_zoom.x -= 0.1
			target_zoom.y -= 0.1

	elif Input.is_action_just_pressed("KEY_ZOOM_IN"):
		if target_zoom.x < 1:
			target_zoom.x += 0.1
			target_zoom.y += 0.1

	zoom = zoom.move_toward(target_zoom, _delta)

	if Input.is_action_pressed("KEY_DRAG_CAMERA"):
		var current_mouse_position = get_viewport().get_mouse_position()
		if Input.is_action_just_pressed("KEY_DRAG_CAMERA"):
			last_mouse_position = current_mouse_position
		var diff = current_mouse_position - last_mouse_position
		position -= diff / zoom
		last_mouse_position = current_mouse_position

	var input_direction = Input.get_vector("KEY_LEFT", "KEY_RIGHT", "KEY_UP", "KEY_DOWN")
	if input_direction.x < 0:
		position.x -= 40
	elif input_direction.x > 0:
		position.x += 40

	if input_direction.y < 0:
		position.y -= 40
	elif input_direction.y > 0:
		position.y += 40

	position = position.clamp(bounds.position, bounds.end)


## set camera bounds
func set_bounds(bounds_global_position : Rect2) -> void:
	bounds = bounds_global_position
	position = bounds_global_position.get_center()
