class_name BattleMagicEffect
extends Resource

@export var name : String = ""
@export var icon_path : String = ""

@export var spell_effects : Array[BattleMagicEffect]

## magical effects last only for 6 turns
var duration_counter : int = 6



## used to debug
func _to_string() -> String:
	return "BattleMagicEffect: " + name


func apply_effect(target : Unit, event_type : String) -> void:
	match name:
		"Vengeance":
			if event_type == "post death spell effect":
				target.try_adding_magic_effect(spell_effects[0])
