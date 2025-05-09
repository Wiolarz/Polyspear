class_name Unit
extends RefCounted # default

signal unit_died()
signal unit_turned()
signal unit_moved()
signal unit_magic_effect()

const MAX_EFFECTS_PER_UNIT = 2

signal unit_is_shooting(side : int, attacker_coord : Vector2i)
signal unit_is_slashing(side : int)
signal unit_is_pushing(side : int)
signal unit_is_blocking(side : int, attacker_coord : Vector2i)
signal unit_is_counter_attacking(side : int)

signal unit_captured_mana(target_tile : Vector2i)  # change visuals of the tile to mark it as captured


## TODO remove this
var controller : Player

## reference to army to which the unit belongs
var army_in_battle : BattleGridState.ArmyInBattleState

## units constant stats resource
var template : DataUnit

## coordinates on a battle grid
var coord : Vector2i

## see E.GridDirections, int for convinience
var unit_rotation : int

## unit died
var dead : bool

## list of spells unit can cast (all of those are one-time use only)
var spells : Array[BattleSpell] = []

## magic effects, size_limit == 2
var effects : Array[BattleMagicEffect] = []

var is_on_swamp : bool = false

# TEMP implementation, should be merged with is_on_swamp and other terrain based effects
## this information is only for visual representation
var is_on_rock : bool = false
var is_on_mana : bool = false

static func create(new_controller : Player, \
		new_template : DataUnit, \
		new_coord : Vector2i, \
		new_rotation : GenericHexGrid.GridDirections, \
		new_army_in_battle_state : BattleGridState.ArmyInBattleState) -> Unit:
	var result = Unit.new()
	result.controller = new_controller
	result.army_in_battle = new_army_in_battle_state
	result.template = new_template
	result.coord = new_coord
	result.unit_rotation = new_rotation
	result.spells = new_template.spells.duplicate() # spells reset every battle
	return result

#region Emit Animation Signals

## turns unit front to a given side, can be awaited see waits_for_form
func turn(side : GenericHexGrid.GridDirections):
	if side == unit_rotation:
		return
	unit_rotation = side
	print("emit turn [turn]")
	unit_turned.emit()


## puts unit to a given coordinate, can be awaited see waits_for_form
func move(new_coord : Vector2i, battle_tile : BattleGridState.BattleHex):
	is_on_swamp = battle_tile.swamp
	is_on_rock = battle_tile.hill
	is_on_mana = battle_tile.mana
	unit_magic_effect.emit()

	var old = coord
	coord = new_coord
	print("emit move [move] %s %s" % [str(old), str(new_coord)])
	unit_moved.emit()


## kills unit, can be awaited see waits_for_form
func unit_killed():
	dead = true
	unit_died.emit()

#endregion Emit Animation Signals


#region Unit Symbols

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

#endregion Unit Symbols


#region Magic

## attempts to add magical effect to a unit (there is limit of 2) [br]
## returns bool if it was succesful
func try_adding_magic_effect(effect : BattleMagicEffect) -> bool:
	if effects.size() >= MAX_EFFECTS_PER_UNIT:
		return false
	effects.append(effect)
	unit_magic_effect.emit()
	return true


## currently used only to update UI
func effect_state_changed() -> void:
	unit_magic_effect.emit()

#endregion Magic


#region Static Symbols

static func does_attack_succeed(attack_symbol : E.Symbols, defense_symbol : E.Symbols):
	return Unit.attack_power(attack_symbol) > Unit.defense_power(defense_symbol)


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
		E.Symbols.AXE, E.Symbols.SPEAR, E.Symbols.BOW, E.Symbols.ATTACK_SHIELD, E.Symbols.FIST, E.Symbols.DAGGER, E.Symbols.SWORD, E.Symbols.MACE:
			return 2  # normal attack
		E.Symbols.STAFF:
			return 1  # weak attack - kills only when enemy defense is 0 (Empty symbol present)
		_:
			return 0


## returns true if symbol can push
static func can_it_push(symbol : E.Symbols) -> bool:
	return Unit.push_power(symbol) > 0


## return how many tiles does weapon pushes enemy away
static func push_power(symbol : E.Symbols) -> int:
	match symbol:
		E.Symbols.MACE:
			return 3
		E.Symbols.FIST:
			return 2
		E.Symbols.PUSH, E.Symbols.STRONG_TOWERSHIELD, E.Symbols.TOWERSHIELD:
			return 1
		_:
			return 0


static func will_parry_occur(attack_symbol : E.Symbols, defense_symbol : E.Symbols):
	return Unit.does_it_parry(defense_symbol) and not Unit.does_it_parry_break(attack_symbol)


static func does_it_parry(symbol : E.Symbols) -> bool:
	match symbol:
		E.Symbols.SWORD, E.Symbols.GREAT_SWORD:
			return true
		_:
			return false


static func does_it_parry_break(symbol : E.Symbols) -> bool:
	match symbol:
		E.Symbols.SCYTHE, E.Symbols.SICKLE:
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
	return Unit.ranged_weapon_reach(symbol) > 0



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

#endregion Static Symbols
