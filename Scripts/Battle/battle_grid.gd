# Singleton B-GRID
extends GridManager


var max_player_number : int

var summon_tiles : Array = []  # Array[Array[HexTile]] seperated by player lists all possible tiles units can be summoned to



var current_spawn : String = "sentinel"

#region Tools

func change_unit_cord(unit, cord : Vector2i):

	unit_grid[unit.cord.x][unit.cord.y] = null# clean your previous location
	unit_grid[cord.x][cord.y] = unit# unit_grid Update

	unit.cord = cord# update unit Index
	
	# Move visuals of the unit
	if BM.unsummoned_units_counter > 0:
		unit.global_position = tile_grid[cord.x][cord.y].global_position
	else:
		unit.move(tile_grid[cord.x][cord.y])
	



func remove_unit(unit):

	var cord : Vector2i = unit.cord
	unit_grid[cord.x][cord.y] = null # Remove unit from gameplay grid
	unit.destroy()

#endregion


#region Coordinates tools


func get_tile_type(cord : Vector2i) -> String:
	return tile_grid[cord.x][cord.y].type

func get_unit(cord : Vector2i):
	return unit_grid[cord.x][cord.y]



func adjacent_units(start_cord : Vector2i) -> Array:
	# Returns 6 elements Array, elements can be null
	var units = []
	for side in range(6):
		var cord = GridManager.adjacent_cord(start_cord, side)
		var neighbour = unit_grid[cord.x][cord.y]
		#if (neighbour != null):
		units.append(neighbour)
	return units


func get_shot_target(start_cord : Vector2i, side : int) -> AUnit:
	while tile_grid[start_cord.x][start_cord.y].type != "sentinel":
		start_cord += DIRECTIONS[side]
		var target = unit_grid[start_cord.x][start_cord.y]
		if target != null:
			return target
	return null


func get_distant_unit(start_cord : Vector2i, side : int, distance : int) -> AUnit:
	for i in range(distance):
		start_cord += DIRECTIONS[side]
	
	return unit_grid[start_cord.x][start_cord.y]


func get_distant_tile_type(start_cord : Vector2i, side : int, distance : int) -> String:
	for i in range(distance):
		start_cord += DIRECTIONS[side]

	return tile_grid[start_cord.x][start_cord.y].type


func get_distant_cord(start_cord : Vector2i, side : int, distance : int) -> Vector2i:
	for i in range(distance):
		start_cord += DIRECTIONS[side]
	
	return start_cord


# func get_melee_targets(start_Cord : Vector2i, direction, symbol_side : int) -> Array[AUnit]:
# 	"""
# 	AI/UI tool
# 	take a side on which a weapon symbol is present -> simulate movement -> return list of damaged targets
# 	(can return friednly units)
	
# 	direction : int / Vector2i

# 	"""
# 	var units : Array[AUnit] = []
	
# 	return units

#endregion


#region Generate Grid
func is_clear() -> bool:
	var clearness = tile_grid.size() == 0 and unit_grid.size() == 0 and summon_tiles.size() == 0
	if not clearness:
		print("ERROR battle_grid is_clear()  tile_grid ", tile_grid.size(), "  unit_grid", unit_grid.size(), "  summon_tiles ", summon_tiles.size())
	return clearness

func reset_data():
	super.reset_data()
	summon_tiles = []



func init_tile_grid() -> void:
	super.init_tile_grid()
	for i in range(max_player_number):
		summon_tiles.append([])





#endregion
