class_name DataBattleMap

extends DataGenericMap


func apply_data() -> void:
	B_GRID.map_information = self  # : DataGenericMap : DataBattleMap

	B_GRID.max_player_number = max_player_number
	B_GRID.grid_width = grid_width
	B_GRID.grid_height = grid_height


static func get_network_id(battle_map : DataBattleMap) -> String:
	return battle_map.resource_path.get_file() if battle_map else ""


static func from_network_id(network_id : String) -> DataBattleMap:
	if network_id.is_empty():
		return null
	return load("%s/%s" % [ CFG.BATTLE_MAPS_PATH, network_id ]) as DataBattleMap
