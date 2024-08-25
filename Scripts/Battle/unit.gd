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

var spells : Array[BattleSpell] = []

var effects : Array[BattleSpell] = []

var is_on_swamp : bool = false


static func create(new_controller : Player, \
		new_template : DataUnit, \
		new_coord : Vector2i, \
		new_rotation : GenericHexGrid.GridDirections) -> Unit:
	var result = Unit.new()
	result.controller = new_controller
	result.template = new_template
	result.coord = new_coord
	result.unit_rotation = new_rotation
	result.spells = new_template.spells.duplicate() # spells reset every battle
	return result


## turns unit front to a given side, can be awaited see waits_for_form
func turn(side : GenericHexGrid.GridDirections):
	if side == unit_rotation:
		return
	unit_rotation = side
	print("emit turn [turn]")
	unit_turned.emit()


## puts unit to a given coordinate, can be awaited see waits_for_form
func move(new_coord : Vector2i, is_swamp : bool):
	is_on_swamp = is_swamp

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


## gets symbol facing specified directin on the battle map, if unit was rotated in given dir [br]
## side_world - direction unit is turned toward [br]
## hypotetical_rotation - unit side it's symbol
func get_symbol_when_rotated(side_world : int, hypotetical_rotation : int) -> E.Symbols:
	if is_on_swamp:
		return E.Symbols.EMPTY
	var side_local : int = GenericHexGrid.rotate_clockwise( \
			side_world as GenericHexGrid.GridDirections, -hypotetical_rotation)
	return template.symbols[side_local].type


func get_front_symbol() -> E.Symbols:
	if is_on_swamp:
		return E.Symbols.EMPTY
	return template.symbols[GenericHexGrid.DIRECTION_FRONT].type


func get_player_color() -> DataPlayerColor:
	if not controller:
		return CFG.NEUTRAL_COLOR
	return controller.get_player_color()



## 0 no shield, 1 weak shield (any symbol), 2 normal shield, 3 strong shield
static func defense_power(symbol : E.Symbols) -> int:
	match symbol:
		E.Symbols.EMPTY:
			return 0
		E.Symbols.STRONG_SHIELD, E.Symbols.STRONG_TOWERSHIELD:
			return 3
		E.Symbols.SHIELD, E.Symbols.ATTACK_SHIELD, E.Symbols.TOWERSHIELD:
			return 2

		_:
			return 1

## power has to bigger than defense power to kill a unit
static func attack_power(symbol : E.Symbols) -> int:
	match symbol:
		E.Symbols.STRONG_AXE, E.Symbols.STRONG_SPEAR:
			return 3  # strong attack pierces normal shields
		E.Symbols.AXE, E.Symbols.SPEAR, E.Symbols.BOW, E.Symbols.ATTACK_SHIELD, E.Symbols.FIST, E.Symbols.DAGGER, E.Symbols.SWORD:
			return 2  # normal attack
		E.Symbols.STAFF, E.Symbols.MACE:
			return 1  # weak attack - kills only when enemy defense is 0 (Empty symbol present)
		_:
			return 0

## returns true if symbol can push
static func can_it_push(symbol : E.Symbols) -> bool:
	match symbol:
		E.Symbols.MACE, E.Symbols.FIST:
			return true
		E.Symbols.STRONG_TOWERSHIELD, E.Symbols.TOWERSHIELD: # shields
			return true
		E.Symbols.PUSH: # classic
			return true
		_:
			return false


static func does_it_parry(symbol : E.Symbols) -> bool:
	match symbol:
		E.Symbols.SWORD:
			return true
		_:
			return false


static func does_it_counter_attack(symbol : E.Symbols) -> bool:
	match symbol:
		E.Symbols.SPEAR, E.Symbols.STRONG_SPEAR:
			return true
		_:
			return false


static func does_it_shoot(symbol : E.Symbols) -> bool:
	match symbol:
		E.Symbols.BOW, E.Symbols.DAGGER:
			return true
		_:
			return false


## return how many tiles does range weapon attack can reach [br]
## -1 = infinite
static func ranged_weapon_reach(symbol : E.Symbols) -> int:
	match symbol:
		E.Symbols.BOW:
			return 4
		E.Symbols.DAGGER:
			return 2
		_:
			return 0
