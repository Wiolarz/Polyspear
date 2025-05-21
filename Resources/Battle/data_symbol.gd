class_name DataSymbol
extends Resource

@export var symbol_name : String
@export var texture_path : String
@export var symbol_animation : SymbolAnimation

## power has to bigger than defense power to kill a unit
@export var attack_power : int = 0

## 0 no shield, 1 weak shield (any symbol), 2 normal shield, 3 strong shield
@export var defense_power : int = 1


@export var push_power : int = 0

@export var counter_attack : bool = false

@export var parry : bool = false
@export var parry_break : bool = false

## return how many tiles does range weapon attack can reach [br]
## -1 = infinite
@export var reach : int = 0


#Both false is a passive weapon (shield)
# turn only - bow
# move only - javelin
## Determines if symbol activates during rotation
@export var activate_turn : bool = true
## Determines if symbol activates during movement
@export var activate_move : bool = true


#region Effects

## returns true if symbol can push push_power > 0
func can_it_push() -> bool:
	return push_power > 0


## attack_power > defense_symbol.defense_power
func does_attack_succeed(defense_symbol : DataSymbol) -> bool:
	return attack_power > defense_symbol.defense_power


## will_parry_occur (check parry break)
func will_melee_effect_occur(defense_symbol : DataSymbol) -> bool:
	if parry_break:
		return true
	return not defense_symbol.parry


## reach > 0
func does_it_shoot() -> bool:
	return reach > 0


## does activate at this action type and does it deal damage or pushes
func is_offensive(action_type : E.MoveType) -> bool:
	if (action_type == E.MoveType.TURN and activate_turn) or \
	   (action_type == E.MoveType.MOVE and activate_move):
		return attack_power > 0 or push_power > 0
	else:
		return false

#endregion Effects
