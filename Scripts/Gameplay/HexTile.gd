class_name HexTile

extends Area2D

var TileIndex : Vector2i

var TileType : E.HexTileType

func _on_input_event(_viewport:Node, event:InputEvent, _shape_idx:int):
	if event.is_action_pressed("KEY_SELECT"):
		GM.InputListener(TileIndex)
