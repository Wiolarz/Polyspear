class_name Unit
extends RefCounted # default

signal select_request(is_selected : bool)
signal unit_died()
signal unit_turned()
signal unit_moved()
signal anim_end()

var controller : Player

## units constant stats resource
var template : DataUnit

## coordinates on a battle grid
var coord : Vector2i

## see E.GridDirections, int for convinience
var unit_rotation : int

## bool to indicate weather unit synchs with some animations or not
var waits_for_form : bool

## unit died and waits for kill anim to end
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
	unit_rotation = side
	if waits_for_form:
		unit_turned.emit()
		await anim_end


## puts unit to a given coordinate, can be awaited see waits_for_form
func move(new_coord : Vector2i):
	coord = new_coord
	if waits_for_form:
		unit_moved.emit()
		await anim_end


## kills unit, can be awaited see waits_for_form
func die():
	dead = true
	if waits_for_form:
		unit_died.emit()
		await anim_end


func can_defend(side : int) -> bool:
	return get_symbol(side) == E.Symbols.SHIELD


func get_symbol(side_world : int) -> E.Symbols:
	var side_local : int = GenericHexGrid.rotate_clockwise( \
			side_world as GenericHexGrid.GridDirections, -unit_rotation)
	return template.symbols[side_local].type

func get_front_symbol() -> E.Symbols:
	return template.symbols[GenericHexGrid.DIRECTION_FRONT].type

## can i kill this enemy in melee if i attack in specified direction
func can_kill(other_unit : Unit, attack_direction : int):
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

func get_player_color_dictionary() -> Dictionary:
	if not controller:
		return CFG.NEUTRAL_COLOR
	return controller.get_player_color_dictionary()
