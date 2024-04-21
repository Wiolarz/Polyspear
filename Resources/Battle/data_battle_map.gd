class_name DataBattleMap

extends DataGenericMap


func apply_data() -> void:
	B_GRID.map_information = self  # : DataGenericMap : DataBattleMap

	B_GRID.max_player_number = max_player_number
	B_GRID.grid_width = grid_width
	B_GRID.grid_height = grid_height
