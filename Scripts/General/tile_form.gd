class_name TileForm

extends Area2D

var coord : Vector2i

var type : String = "sentinel"

var place : Place

var grid_type : GameSetupInfo.GameMode = GameSetupInfo.GameMode.WORLD


func _on_input_event(_viewport : Node, event : InputEvent, _shape_idx : int):
	if event.is_action_pressed("KEY_SELECT"): # normal gameplay
		IM.grid_input_listener(coord, grid_type)

	if Input.is_action_pressed("KEY_SELECT"): # for map draw
		IM.grid_smooth_input_listener(coord, grid_type)


func set_coord(c:Vector2i)->void:
	coord = c
	$CoordLabel.text = str(coord)


func to_battle_grid_enum() -> int:
	match type:
		"sentinel":   return 1
		"wall":      return 1
		"":      return 1 # IMPASSABLE
		"blue_spawn": return 0
		"red_spawn":  return 0
		"empty":      return 0
	return 1

func _process(_delta):
	$PlaceLabel.text = ""
	if place != null: #TEMP
		$PlaceLabel.text = place.get_map_description()
