class_name DataTile

extends Resource

## use snake_case [br]
## when adding new types update unit tests datasets
@export var type : String

@export var texture_path : String

## TODO - yet to be implemented
@export var flip_horizontal : bool = false


static func create_data_tile(hex_tile : TileForm) -> DataTile:
	var new_data_tile = DataTile.new()

	var sprite_node : Sprite2D = hex_tile.get_node("Sprite2D")
	var new_path = sprite_node.texture.resource_path
	new_data_tile.texture_path = new_path

	new_data_tile.type = hex_tile.type

	return new_data_tile


func is_spawn_tile() -> bool:
	return type == "city" or type == "elf_city" or type == "orc_city"
