# Singleton B-GRID
extends GridManager

var max_player_number : int

## Array[Array[TileForm]] player, index -> TileForm
## lists all tiles that can be used to summon units for a given player
var summon_tiles : Array = []

#region Tools

func spawn_unit_at_coord(unit : Unit, coord : Vector2i):
	assert(get_unit(coord) == null, "error, spawningg onto a non empty field")
	unit_grid[coord.x][coord.y] = unit # unit_grid Update


func change_unit_coord(unit : Unit, coord : Vector2i):
	assert(get_unit(unit.coord) == unit, "error, desync on unit coord")
	assert(get_unit(coord) == null, "error, moving into a non empty field")
	unit_grid[unit.coord.x][unit.coord.y] = null # clean your previous location
	unit_grid[coord.x][coord.y] = unit # unit_grid Update


func remove_unit(unit : Unit):
	var coord : Vector2i = unit.coord
	assert(get_unit(coord) == unit, "error, desync on unit coord")
	unit_grid[coord.x][coord.y] = null # Remove unit from gameplay grid

#endregion


#region Coordinates tools


func get_shot_target(start_coord : Vector2i, side : int) -> Unit:
	var coord_to_check = start_coord
	while get_tile_type(coord_to_check) != "sentinel":
		coord_to_check += DIRECTIONS[side]
		#print("checking ",start_coord)
		var target = get_unit(coord_to_check)
		if target != null:
			#print("hit @",start_coord)
			return target
	#print("missed")
	return null


# func get_melee_targets(start_coord : Vector2i, direction, symbol_side : int) -> Array[UnitForm]:
# 	"""
# 	AI/UI tool
# 	take a side on which a weapon symbol is present -> simulate movement
#		-> return list of damaged targets
# 	(can return friendly units)

# 	direction : int / Vector2i

# 	"""
# 	var units : Array[UnitForm] = []

# 	return units

#endregion


#region Generate Grid


func on_tile_spawned(tile: TileForm) -> void:
	tile.grid_type = GameSetupInfo.GameMode.BATTLE


func is_clear() -> bool:
	var clearness = tile_grid.size() == 0 and unit_grid.size() == 0 and summon_tiles.size() == 0
	if not clearness:
		print("ERROR battle_grid is_clear()  tile_grid ", tile_grid.size(), \
				"  unit_grid", unit_grid.size(), "  summon_tiles ", summon_tiles.size())
	return clearness


func reset_data():
	super.reset_data()
	summon_tiles = []


func init_tile_grid() -> void:
	super.init_tile_grid()
	for i in range(max_player_number):
		summon_tiles.append([])

#endregion
