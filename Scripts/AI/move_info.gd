class_name MoveInfo
extends Resource

const TYPE_MOVE = "move"
const TYPE_SUMMON = "summon"

@export var move_type: String = ""
@export var summon_unit: DataUnit
@export var move_source: Vector2i
@export var target_tile_coord: Vector2i


# for undo, do not serialize
var army_idx : int = -1
var original_rotation : int = -1
var units_killed : Array[KilledUnit] = []
var units_pushed: Array[PushedUnit] = []


static func make_move(src : Vector2i, dst : Vector2i) -> MoveInfo:
	var result:MoveInfo = MoveInfo.new()
	result.move_type = TYPE_MOVE
	result.move_source = src
	result.target_tile_coord = dst
	return result


static func make_summon(unit : DataUnit, dst : Vector2i) -> MoveInfo:
	var result:MoveInfo = MoveInfo.new()
	result.move_type = TYPE_SUMMON
	result.summon_unit = unit
	result.target_tile_coord = dst
	return result


func to_network_serializable() -> Dictionary:
	return {
		"move_type" : move_type,
		"move_source" : move_source,
		"target_tile_coord": target_tile_coord,
		"summon_unit": DataUnit.get_network_id(summon_unit),
	}


static func from_network_serializable(dict : Dictionary) -> MoveInfo:
	match dict["move_type"]:
		MoveInfo.TYPE_SUMMON:
			return MoveInfo.make_summon( \
				DataUnit.from_network_id(dict["summon_unit"]),\
					dict["target_tile_coord"])
		MoveInfo.TYPE_MOVE:
			return MoveInfo.make_move(dict["move_source"],
					dict["target_tile_coord"])
	push_error("move_type not supported: ", dict["move_type"])
	return null


func _to_string() -> String:
	if move_type == TYPE_SUMMON:
		return TYPE_SUMMON + " " + str(target_tile_coord) + " " + summon_unit.unit_name
	return move_type + " " + str(target_tile_coord) + " from " + str(move_source)


class KilledUnit:
	var army_idx: int
	var template : DataUnit
	var coord : Vector2i
	var unit_rotation : int

	static func create(army_idx_:int, unit:Unit) -> KilledUnit:
		var result = KilledUnit.new()
		result.army_idx = army_idx_
		result.coord = unit.coord
		result.template = unit.template
		result.unit_rotation = unit.unit_rotation
		return result

	func respawn() -> Unit:
		var result = Unit.new()
		result.coord = coord
		result.template = template
		result.unit_rotation = unit_rotation
		return result


class PushedUnit:
	var from_coord : Vector2i
	var to_coord : Vector2i
