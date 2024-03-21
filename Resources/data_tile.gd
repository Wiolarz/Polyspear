class_name DataTile

extends Resource


@export var texture_path : String

@export var flip_horizontal : bool = false


"""


"""

@export var gameplay_function : String


static func create_data_tile(hex_tile : HexTile) -> DataTile:
	var new_data_tile = DataTile.new()

	var sprite_node : Sprite2D = hex_tile.get_node("Sprite2D")
	var new_path = sprite_node.texture.resource_path
	new_data_tile.texture_path = new_path

	new_data_tile.gameplay_function = str(hex_tile.tile_type)

	return new_data_tile