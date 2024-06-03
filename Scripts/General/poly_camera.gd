class_name PolyCamera
extends Camera2D

const ZOOM_SPEED = 2.0
const MOVE_SPEED = 40.0

var last_mouse_position : Vector2
var target_zoom : Vector2 = Vector2(0.5, 0.5)
var bounds : Rect2 = Rect2(0,0,10000,10000)

var direction_actions = ["KEY_LEFT", "KEY_RIGHT", "KEY_UP", "KEY_DOWN"]
var directions_pressed = [false, false, false, false]

func process_input_event(event : InputEvent) -> void:
	if event.is_action_pressed("KEY_ZOOM_OUT"):
		if target_zoom.x > 0.11: # float precision
			target_zoom.x -= 0.1
			target_zoom.y -= 0.1
	elif event.is_action_pressed("KEY_ZOOM_IN"):
		if target_zoom.x < 1:
			target_zoom.x += 0.1
			target_zoom.y += 0.1

	for i in range(direction_actions.size()):
		var action = direction_actions[i]
		if not event.is_action(action):
			continue
		directions_pressed[i] = event.is_pressed()

func get_camera_move() -> Vector2:
	var result = Vector2(0,0)
	if (directions_pressed[0]): result.x -= 1
	if (directions_pressed[1]): result.x += 1
	if (directions_pressed[2]): result.y -= 1
	if (directions_pressed[3]): result.y += 1
	return result.normalized()


func process_camera(delta):
	zoom = zoom.move_toward(target_zoom, delta * ZOOM_SPEED)

	if Input.is_action_pressed("KEY_DRAG_CAMERA"):
		process_camera_drag()

	position += MOVE_SPEED * get_camera_move()
	position = position.clamp(bounds.position, bounds.end)


func center_camera(node: Node2D):
	position = node.position


func process_camera_drag():
	var current_mouse_position = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("KEY_DRAG_CAMERA"):
		last_mouse_position = current_mouse_position
	var diff = current_mouse_position - last_mouse_position
	position -= diff / zoom
	last_mouse_position = current_mouse_position


## set camera bounds
func set_bounds(bounds_global_position : Rect2) -> void:
	bounds = bounds_global_position
	position = bounds_global_position.get_center()
