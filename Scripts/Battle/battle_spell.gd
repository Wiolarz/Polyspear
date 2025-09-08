@tool
class_name BattleSpell
extends Resource

@export var name : String = ""
@export_file var icon_path : String = ""
@export_multiline var description : String = ""
## optional, used when spell applies an effect to a unit
@export var spell_effects : Array[BattleMagicEffect]

## optional, used only by summon spells
@export var summon_unit_data : DataUnit

##STUB category
@export_category("restrictions for spell targeting")


## -1 infinite | 0 allows only to cast on itself
@export var axial_cast_range : int = -1 :
	set(value):
		axial_cast_range = value
		notify_property_list_changed()

enum DirectionCast {ANY, FRONT, STRAIGHT}
@export var direction_cast := DirectionCast.ANY


enum TargetType {ANY, UNIT, EMPTY_TILE}

@export var target_type := TargetType.ANY :
	set(value):
		target_type = value
		notify_property_list_changed()


# TILE CATEGORY

var needs_movable_tile : bool = false


# Unit Category

enum TargetUnitType {ANY, ALLY, ENEMY}
var target_unit_type := TargetUnitType.ANY
var not_self : bool = false



func _get_property_list() -> Array[Dictionary]:
	# By default, `hammer_type` is not visible in the editor.

	var not_self_property = PROPERTY_USAGE_NO_EDITOR
	var tile_properties = PROPERTY_USAGE_NO_EDITOR
	var unit_properties = PROPERTY_USAGE_NO_EDITOR

	if target_type == TargetType.UNIT:
		unit_properties = PROPERTY_USAGE_DEFAULT

	if target_type == TargetType.EMPTY_TILE:
		tile_properties = PROPERTY_USAGE_DEFAULT

	if axial_cast_range != 0 and not needs_movable_tile:
		not_self_property = PROPERTY_USAGE_DEFAULT

	var properties :  Array[Dictionary] = []

	properties.append({
		"name": "needs_movable_tile",
		"type": TYPE_BOOL,
		"usage": tile_properties,
	})

	## UNITS

	var target_unit_types_string = ""
	for value in TargetUnitType.keys():
		target_unit_types_string += value + ","
	target_unit_types_string = target_unit_types_string.trim_suffix(",")
	#print(target_unit_types_string)

	properties.append({
		"name": "target_unit_type",
		"type": TYPE_INT,
		"usage": unit_properties,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": target_unit_types_string,
	})


	properties.append({
		"name": "not_self",
		"type": TYPE_BOOL,
		"usage": not_self_property, # See above assignment.
	})

	return properties


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


## Based of event type applies effect to the target unit [br]
## each new effects needs to be addded here
func cast_effect(target : Unit, event_type : String) -> void:
	match name:
		"Vengeance", "Blood Ritual", "Martyr", "Anchor":
			if event_type == "casting":
				target.try_adding_magic_effect(spell_effects[0].duplicate())


static func get_network_id(spell : BattleSpell) -> String:
	if not spell:
		return ""
	assert(spell.resource_path.begins_with(CFG.SPELLS_PATH), \
			"spell serialization not supported")
	return spell.resource_path.trim_prefix(CFG.SPELLS_PATH)


static func from_network_id(network_id : String) -> BattleSpell:
	if network_id.is_empty():
		return null
	print("loading BattleSpell - ","%s/%s" % [ CFG.SPELLS_PATH, network_id ])
	return load("%s/%s" % [ CFG.SPELLS_PATH, network_id ]) as BattleSpell
