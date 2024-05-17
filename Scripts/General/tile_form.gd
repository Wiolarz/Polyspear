class_name TileForm

extends Area2D

var coord : Vector2i

var type : String = "sentinel"

var place : Place

var grid_type : GameSetupInfo.GameMode = GameSetupInfo.GameMode.WORLD


func _on_input_event(_viewport : Node, event : InputEvent, _shape_idx : int):
	# normal gameplay - on click
	if event.is_action_pressed("KEY_SELECT"):
		UI.grid_input_listener(coord, grid_type, false)

	# for map editor - on mouse move while button pressed
	if Input.is_action_pressed("KEY_SELECT"):
		UI.grid_input_listener(coord, grid_type, true)


func set_coord(c:Vector2i)->void:
	coord = c
	$CoordLabel.text = str(coord)


func _process(_delta):
	$PlaceLabel.text = ""
	if place != null: #TEMP
		$PlaceLabel.text = place.get_map_description()
