class_name MoveInfo
extends RefCounted


var move_type: String = ""
var summon_unit: DataUnit
var move_source: Vector2i
var target_tile_coord: Vector2i

const TYPE_MOVE = "move"
const TYPE_SUMMON = "summon"


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
