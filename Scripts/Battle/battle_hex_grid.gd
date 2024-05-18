class_name BattleHexGrid
extends GenericHexGrid

const MOVE_IS_INVALID = -1

func _init(new_width:int, new_height:int):
	super(new_width, new_height, BattleHex.sentinel)


static func create(map: DataBattleMap) -> BattleHexGrid:
	var result = BattleHexGrid.new(map.grid_width, map.grid_height)
	for x in range(map.grid_width):
		for y in range(map.grid_height):
			var map_tile := map.grid_data[x][y] as DataTile
			result.set_hex(Vector2i(x,y), BattleHex.create(map_tile))
	return result


func get_battle_hex(coord : Vector2i) -> BattleHex:
	return get_hex(coord) as BattleHex


func can_summon_on(army_idx : int, coord : Vector2i) -> bool:
	var hex = get_battle_hex(coord)
	return  not hex.unit and hex.spawn_point_army_idx == army_idx


func get_summon_coords(army_idx : int) -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	for x in range(width):
		for y in range(height):
			var coord = Vector2i(x,y)
			if can_summon_on(army_idx, coord):
				result.append(coord)
	return result


func spawn_unit_at_coord(unit : Unit, coord : Vector2i) -> void:
	var hex = get_battle_hex(coord)
	assert(hex.can_be_moved_to, "summoning unit to an invalid tile")
	assert(not hex.unit, "summoning unit to an occupied tile")
	hex.unit = unit


func get_unit(coord : Vector2i)->Unit:
	return get_battle_hex(coord).unit


func change_unit_coord(unit : Unit, target_coord : Vector2i) -> void:
	remove_unit(unit)
	spawn_unit_at_coord(unit, target_coord)


func remove_unit(unit : Unit) -> void:
	var hex = get_battle_hex(unit.coord)
	assert(hex.unit == unit, "incorrect remove unit, coord desync")
	hex.unit = null


func is_moveable(coord : Vector2i) -> bool:
	return get_battle_hex(coord).can_be_moved_to


func adjacent_units(coord : Vector2i) -> Array[Unit]:
	var result : Array[Unit] = []
	for dir in range(6):
		var target_coord = GenericHexGrid.adjacent_coord(coord, dir)
		result.append(get_unit(target_coord))
	return result


func get_shot_target(coord : Vector2i, direction : int) -> Unit:
	var target_coord = GenericHexGrid.adjacent_coord(coord, direction)
	var hex = get_battle_hex(target_coord)
	while not hex.unit and not hex.blocks_shots():
		target_coord = GenericHexGrid.adjacent_coord(target_coord, direction)
		hex = get_battle_hex(target_coord)
	return hex.unit


## Returns `MOVE_IS_INVALID` if move is incorrect
## or a turn direction `E.GridDirections` if move is correct
func get_move_direction_if_valid(unit : Unit, coord : Vector2i) -> int:
	"""
		Function checks 2 things:
		1 Target coord is a Neighbor of a selected_unit
		2a Target coord is empty
		2b Target coord contains unit that can be killed

		@param unit to move
		@param coord target coord for selected_unit to move to
		@return MOVE_IS_INVALID (-1) if move is illegal, direction otherwise
	"""

	var move_direction = GenericHexGrid.direction_to_adjacent(unit.coord, coord)
	# not adjacent
	if move_direction == TILES_NOT_ADJACENT:
		return MOVE_IS_INVALID

	var hex = get_battle_hex(coord)
	if not hex.can_be_moved_to:
		return MOVE_IS_INVALID

	var unit_on_target = hex.unit
	# empty field
	if not unit_on_target:
		return move_direction

	if not unit.can_kill(unit_on_target, move_direction):
		return MOVE_IS_INVALID

	return move_direction

class BattleHex:
	var can_be_moved_to: bool
	var unit : Unit
	var spawn_point_army_idx : int

	static var sentinel: BattleHex = BattleHex.new()

	func _init():
		can_be_moved_to = false
		spawn_point_army_idx = -1

	static func create(data : DataTile):
		if data.type == "sentinel":
			return null
		var result = BattleHex.new()
		result.can_be_moved_to = true
		match data.type:
			"red_spawn":
				result.spawn_point_army_idx = 0
			"blue_spawn":
				result.spawn_point_army_idx = 1
		return result

	func blocks_shots() -> bool:
		return not can_be_moved_to
