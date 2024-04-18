class_name HexTile

extends Area2D

var cord : Vector2i

var type : String = "sentinel"

func _on_input_event(_viewport:Node, event:InputEvent, _shape_idx:int):
	if Input.is_action_pressed("KEY_SELECT"):
		IM.grid_input_listener(cord)
	

func set_coord(c:Vector2i)->void:
	cord = c
	$CoordLabel.text = str(cord)
