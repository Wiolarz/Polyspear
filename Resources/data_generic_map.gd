class_name DataGenericMap  # GridMap is reserved for 3D

extends Resource

@export var max_player_number : int = 2

@export var grid_width : int = 5
@export var	grid_height : int = 5

@export var grid_data : Array  # Array[Array[DataTile]]

func is_on_grid(coord : Vector2i):
	return coord.x >= 0 and coord.y >= 0 \
		and coord.x < grid_width and coord.y < grid_height

func apply_data() -> void:
	pass
