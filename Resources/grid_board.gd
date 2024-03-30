class_name GridBoard  # GridMap is reserved for 3D

extends Resource

@export var max_player_number : int = 2

@export var grid_width : int = 5
@export var	grid_height : int = 5



@export var grid_data : Array  # Array[Array[tile]]


func apply_data() -> void:
	pass