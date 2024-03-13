class_name HexTile

extends Area2D

var cord : Vector2i

var tile_type : E.HexTileType


func _on_input_event(_viewport:Node, event:InputEvent, _shape_idx:int):
	if event.is_action_pressed("KEY_SELECT"):
		BM.input_listener(cord)
