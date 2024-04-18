class_name WorldMap

extends GridBoard

"""
Placeholder variables.

Complete world map data:
	1 Placement of every tile type
	2 Info about assignment of every city
"""



func get_spawn_locations() -> Array[Vector2i]:
	"""
	returns coordinates of cities in basic order (first occurence in array)
	"""
	var spawn_locations : Array[Vector2i] = []
	for x in range(grid_data.size()):
		for y in range(grid_data[x].size()):
			if grid_data[x][y].is_spawn_tile():
				spawn_locations.append(Vector2i(x, y))
	
	
	return spawn_locations


func apply_data() -> void:
	W_GRID.map_information = self  # : GridBoard : WorldMap
	W_GRID.max_player_number = max_player_number
	W_GRID.grid_width = grid_width
	W_GRID.grid_height = grid_height
