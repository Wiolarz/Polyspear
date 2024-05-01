class_name TileForm

extends Area2D

var coord : Vector2i

var type : String = "sentinel"

var place : Place


func _on_input_event(_viewport : Node, event : InputEvent, _shape_idx : int):
	if event.is_action_pressed("KEY_SELECT"): # normal gameplay
		IM.grid_input_listener(coord)

	if Input.is_action_pressed("KEY_SELECT"): # for map draw
		IM.grid_smooth_input_listener(coord)


func set_coord(c:Vector2i)->void:
	coord = c
	$CoordLabel.text = str(coord)


func _process(_delta):
	$PlaceLabel.text = ""
	if place != null: #TEMP
		$PlaceLabel.text = place.get_map_description()
