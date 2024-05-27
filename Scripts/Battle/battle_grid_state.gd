class_name BattleGridState
extends GenericHexGrid

const MOVE_IS_INVALID = -1

func _init(width_ : int, height_ : int):
	super(width_, height_, BattleHex.sentinel)


static func create(map: DataBattleMap) -> BattleGridState:
	var result = BattleGridState.new(map.grid_width, map.grid_height)
	for x in range(map.grid_width):
		for y in range(map.grid_height):
			var map_tile : DataTile = map.grid_data[x][y]
			result.set_hex(Vector2i(x,y), BattleHex.create(map_tile))
	return result


func get_battle_hex(coord : Vector2i) -> BattleHex:
	return get_hex(coord)


func can_summon_on(army_idx : int, coord : Vector2i) -> bool:
	var hex := get_battle_hex(coord)
	return  hex.spawn_point_army_idx == army_idx and hex.unit == null


func get_summon_coords(army_idx : int) -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	for x in range(width):
		for y in range(height):
			var coord := Vector2i(x,y)
			if can_summon_on(army_idx, coord):
				result.append(coord)
	return result


func spawn_unit_at_coord(unit : Unit, coord : Vector2i) -> void:
	put_unit_on_grid(unit, coord)


func put_unit_on_grid(unit : Unit, coord : Vector2i) -> void:
	var hex := get_battle_hex(coord)
	assert(hex.can_be_moved_to, "summoning unit to an invalid tile")
	assert(not hex.unit, "summoning unit to an occupied tile")
	hex.unit = unit


func get_unit(coord : Vector2i) -> Unit:
	return get_battle_hex(coord).unit


func change_unit_coord(unit : Unit, target_coord : Vector2i) -> void:
	remove_unit(unit)
	put_unit_on_grid(unit, target_coord)


func remove_unit(unit : Unit) -> void:
	var hex := get_battle_hex(unit.coord)
	assert(hex.unit == unit, "incorrect remove unit, coord desync")
	hex.unit = null


func is_movable(coord : Vector2i) -> bool:
	return get_battle_hex(coord).can_be_moved_to


func adjacent_units(coord : Vector2i) -> Array[Unit]:
	var result : Array[Unit] = []
	for dir in range(6):
		var target_coord := GenericHexGrid.adjacent_coord(coord, dir)
		result.append(get_unit(target_coord))
	return result


func get_shot_target(coord : Vector2i, direction : int) -> Unit:
	var target_coord := GenericHexGrid.adjacent_coord(coord, direction)
	var hex := get_battle_hex(target_coord)
	while not hex.unit and not hex.blocks_shots():
		target_coord = GenericHexGrid.adjacent_coord(target_coord, direction)
		hex = get_battle_hex(target_coord)
	return hex.unit


## Returns `MOVE_IS_INVALID` if move is incorrect
## or a turn direction `E.GridDirections` if move is correct
func get_move_direction_if_valid(unit : Unit, coord : Vector2i) -> int:
	"""
		For move to be valid, target coord
		- is a neighbor of the unit
		- allows movement
		- can be occupied by a new unit:
			- is empty
			- contains a unit that would be killed/pushed by the move

		@param unit to move
		@param coord target coord for unit to move to
		@return MOVE_IS_INVALID (-1) if move is illegal, direction otherwise
	"""

	var move_direction := GenericHexGrid.direction_to_adjacent(unit.coord, coord)
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

	if not unit.can_kill_or_push(unit_on_target, move_direction):
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

		if data.type.substr(1) == "_player_spawn":
			result.spawn_point_army_idx = data.type[0].to_int() - 1

		return result

	func blocks_shots() -> bool:
		return not can_be_moved_to
