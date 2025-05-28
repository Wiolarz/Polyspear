@tool
class_name TextBubble
extends Resource

## description used in "is_prerequisite_fullfilled()" check
@export var prerequisite : String

@export var title : String :
	set(value):
		title = value
		resource_name = value
@export_multiline var text : String

## Optional icon that is displayed next to the speech bubble
@export var icon : Texture2D


#stub
func _decode_prerequisite():
	pass



func is_prerequisite_fullfilled(battle_state : BattleGridState) -> bool:
	if battle_state.current_army_index != 0: # TEMP assumption, that player is always under this index
		return false
	
	var prerequisite_transalted : PackedStringArray = prerequisite.split(" ")
	for pair_idx : int in range(0, prerequisite_transalted.size(), 2):
		var key : String = prerequisite_transalted[pair_idx]
		var value : String  = prerequisite_transalted[pair_idx + 1]

		match key:
			"phase":
				match value:
					"summon":
						if battle_state.state != BattleGridState.STATE_SUMMONNING:
							return false
					"fighting":
						if battle_state.state != BattleGridState.STATE_FIGHTING:
							return false
					"sacrifice":
						if battle_state.state != BattleGridState.STATE_SACRIFICE:
							return false

			"time":
				if int(value) != battle_state.turn_counter:
					return false
			"selected":
				if value == "null":
					if BM._selected_unit:
						return false
					continue
				if not BM._selected_unit or not BM._selected_unit.template.unit_name == value:
					return false
			"mana":
				pass

	return true



