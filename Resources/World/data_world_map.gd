class_name DataWorldMap
extends DataGenericMap

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


static func get_network_id(world_map : DataWorldMap) -> String:
	return world_map.resource_path.get_file() if world_map else ""


static func from_network_id(network_id : String) -> DataWorldMap:
	if network_id.is_empty():
		return null
	return load("%s/%s" % [ CFG.WORLD_MAPS_PATH, network_id ]) as DataWorldMap
