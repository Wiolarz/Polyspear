# Singleton B-GRID
extends GridManager


var max_player_number : int

## Array[Array[HexTile]] player, index -> HexTile
## lists all tiles that can be used to summon units for a given player
var summon_tiles : Array = []

var current_spawn : String = "sentinel"


#region Tools

func get_all_field_coords() -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	for x in range(grid_width):
		for y in range(grid_height):
			result.append(Vector2i(x,y))
	return result


func change_unit_coord(unit : UnitForm, coord : Vector2i):

	unit_grid[unit.coord.x][unit.coord.y] = null# clean your previous location
	unit_grid[coord.x][coord.y] = unit# unit_grid Update

	unit.coord = coord# update unit Index

	# Move visuals of the unit
	if BM.is_during_summoning_phase():
		unit.global_position = tile_grid[coord.x][coord.y].global_position
	else:
		unit.move(tile_grid[coord.x][coord.y])


func remove_unit(unit):

	var coord : Vector2i = unit.coord
	unit_grid[coord.x][coord.y] = null # Remove unit from gameplay grid
	unit.destroy()

#endregion


#region Coordinates tools

func get_tile_type(coord : Vector2i) -> String:
	return tile_grid[coord.x][coord.y].type


func get_unit(coord : Vector2i):
	return unit_grid[coord.x][coord.y]


## Returns 6 elements Array, elements can be null
func adjacent_units(start_coord : Vector2i) -> Array:
	var units = []
	for side in range(6):
		var coord = GridManager.adjacent_coord(start_coord, side)
		var neighbor = unit_grid[coord.x][coord.y]
		units.append(neighbor)
	return units


func get_shot_target(start_coord : Vector2i, side : int) -> UnitForm:
	while tile_grid[start_coord.x][start_coord.y].type != "sentinel":
		start_coord += DIRECTIONS[side]
		#print("checking ",start_coord)
		var target = unit_grid[start_coord.x][start_coord.y]
		if target != null:
			#print("hit @",start_coord)
			return target
	#print("missed")
	return null


func get_distant_unit(start_coord : Vector2i, side : int, distance : int) -> UnitForm:
	for i in range(distance):
		start_coord += DIRECTIONS[side]

	return unit_grid[start_coord.x][start_coord.y]


func get_distant_tile_type(start_coord : Vector2i, side : int, distance : int) -> String:
	for i in range(distance):
		start_coord += DIRECTIONS[side]

	return tile_grid[start_coord.x][start_coord.y].type


func get_distant_coord(start_coord : Vector2i, side : int, distance : int) -> Vector2i:
	for i in range(distance):
		start_coord += DIRECTIONS[side]

	return start_coord


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
