class_name Unit
extends RefCounted # default

signal unit_died()
signal unit_turned()
signal unit_moved()

var controller : Player

## units constant stats resource
var template : DataUnit

## coordinates on a battle grid
var coord : Vector2i

## see E.GridDirections, int for convinience
var unit_rotation : int

## unit died
var dead : bool


static func create(new_controller : Player, \
		new_template : DataUnit, \
		new_coord : Vector2i, \
		new_rotation : GenericHexGrid.GridDirections) -> Unit:
	var result = Unit.new()
	result.controller = new_controller
	result.template = new_template
	result.coord = new_coord
	result.unit_rotation = new_rotation
	return result


## turns unit front to a given side, can be awaited see waits_for_form
func turn(side : GenericHexGrid.GridDirections):
	if side == unit_rotation:
		return
	unit_rotation = side
	print("emit turn [turn]")
	unit_turned.emit()


## puts unit to a given coordinate, can be awaited see waits_for_form
func move(new_coord : Vector2i):
	var old = coord
	coord = new_coord
	print("emit move [move] %s %s" % [str(old), str(new_coord)])
	unit_moved.emit()


## kills unit, can be awaited see waits_for_form
func unit_killed():
	dead = true
	unit_died.emit()


func can_defend(side : int) -> bool:
	return get_symbol(side) == E.Symbols.SHIELD


## gets symbol facing specified directin on the battle map
func get_symbol(side_world : int) -> E.Symbols:
	return get_symbol_when_rotated(side_world, unit_rotation)


## gets symbol facing specified directin on the battle map, if unit was rotated in given dir
func get_symbol_when_rotated(side_world : int, hypotetical_rotation : int) -> E.Symbols:
	var side_local : int = GenericHexGrid.rotate_clockwise( \
			side_world as GenericHexGrid.GridDirections, -hypotetical_rotation)
	return template.symbols[side_local].type

func get_front_symbol() -> E.Symbols:
	return template.symbols[GenericHexGrid.DIRECTION_FRONT].type

## can i kill/push this enemy in melee if i attack in specified direction
func can_kill_or_push(other_unit : Unit, attack_direction : int):
	# - attacker has no attack symbol on front
	# - attacker has push symbol on front (no current unit has it)
	# - attacker has some attack symbol
	#   - defender has shield

	if other_unit.controller == controller:
		return false

	match get_front_symbol():
		E.Symbols.EMPTY:
			# can't deal with enemy_unit
			return false
		E.Symbols.SHIELD:
			# can't deal with enemy_unit
			return false
		E.Symbols.PUSH:
			# push ignores enemy_unit shields etc
			return true
		_:
			# assume other attack symbol
			# Does enemy_unit has a shield?
			var defense_direction = GenericHexGrid.opposite_direction(attack_direction)
			var defense_symbol = other_unit.get_symbol(defense_direction)

			if defense_symbol == E.Symbols.SHIELD:
				return false
			# no shield, attack ok
			return true


func get_player_color() -> DataPlayerColor:
	if not controller:
		return CFG.NEUTRAL_COLOR
	return controller.get_player_color()
