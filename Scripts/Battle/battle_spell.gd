class_name BattleSpell
extends Resource

@export var name : String = ""
@export var icon_path : String = ""

@export var spell_effects : Array[BattleMagicEffect]

## used to debug
func _to_string() -> String:
	return "BattleSpell: " + name


## STUB for magic refactor
func enchanted_unit_dies() -> void:
	match name:
		"Vengeance":
			#get_unit(target_tile_coord).effects.append(spell)
			#print(get_unit(target_tile_coord).effects)
			print("zemsta")
			pass
		_:
			return



func cast_effect(target : Unit, event_type : String) -> void:
	match name:
		"Vengeance":
			if event_type == "casting":
				target.try_adding_magic_effect(spell_effects[0].duplicate())
		"Martyr":
			if event_type == "casting":
				target.try_adding_magic_effect(spell_effects[0].duplicate())

				
				
