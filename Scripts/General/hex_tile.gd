class_name HexTile

extends Area2D

var cord : Vector2i

var type : String = "sentinel"

var place: Place


func _on_input_event(_viewport : Node, event : InputEvent, _shape_idx : int):
	if event.is_action_pressed("KEY_SELECT"): # normal gameplay
		IM.grid_input_listener(cord)
	
	if Input.is_action_pressed("KEY_SELECT"): # for map draw
		IM.grid_smooth_input_listener(cord)
	

func set_coord(c:Vector2i)->void:
	cord = c
	$CoordLabel.text = str(cord)
	
func _process(_delta):
	if place != null:
		$PlaceLabel.text = place.get_map_description()
