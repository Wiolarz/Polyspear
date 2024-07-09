class_name HackWorldEditGrid
extends Node2D


var grid : GenericHexGrid


static func create_empty_tile() -> DataTile:
	return load(CFG.SENTINEL_TILE_PATH)


func load_map(map : DataWorldMap) -> void:
	pass


func size() -> Vector2i:
	return Vector2i(0, 0)


func resize(v : Vector2i) -> void:
	pass


func paint(coord : Vector2i, tile : DataTile) -> void:
	pass


func get_current_map(trim : bool) -> DataWorldMap:
	return null


func get_tile_grid_data() -> Array:
	return grid.hexes
