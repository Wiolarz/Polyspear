class_name WorldMoveInfo
extends Resource

const TYPE_MOVE = "move"
const TYPE_RECRUIT_HERO = "recruit_hero"
const TYPE_RECRUIT_UNIT = "recruit_unit"
const TYPE_BUILD = "build"
const TYPE_END_TURN = "end_turn"

class RecruitHeroInfo extends Resource:
	@export var player_index : int = -1
	@export var data_hero : DataHero


@export var move_type: String = ""
@export var move_source: Vector2i
@export var target_tile_coord: Vector2i
@export var recruit_hero_info : RecruitHeroInfo = null
@export var data : Resource = null
@export var enter_city: bool

#TODO: enter_city_ remove, add other MOVE type for opening city trade
static func make_world_move(src : Vector2i, dst : Vector2i, \
		enter_city_ : bool = false) -> WorldMoveInfo:
	var result : WorldMoveInfo = WorldMoveInfo.new()
	result.move_type = TYPE_MOVE
	result.move_source = src
	result.target_tile_coord = dst
	result.enter_city = enter_city_
	return result


static func make_recruit_hero(player_index : int, data_hero : DataHero, \
		coord : Vector2i) -> WorldMoveInfo:
	var result : WorldMoveInfo = WorldMoveInfo.new()
	result.move_type = TYPE_RECRUIT_HERO
	result.target_tile_coord = coord
	result.recruit_hero_info = RecruitHeroInfo.new()
	result.recruit_hero_info.player_index = player_index
	result.recruit_hero_info.data_hero = data_hero
	return result


static func make_recruit_unit(army_coord : Vector2i, \
		data_unit : DataUnit) -> WorldMoveInfo:
	var result : WorldMoveInfo = WorldMoveInfo.new()
	result.move_type = TYPE_RECRUIT_UNIT
	result.target_tile_coord = army_coord
	result.data = data_unit
	return result


static func make_build(city_coord : Vector2i, \
		building_data : DataBuilding) -> WorldMoveInfo:
	var result : WorldMoveInfo = WorldMoveInfo.new()
	result.move_type = TYPE_BUILD
	result.target_tile_coord = city_coord
	result.data = building_data
	return result


static func make_recruit_hero_from_network(player_index : int, \
		hero : String, coord : Vector2i) -> WorldMoveInfo:
	return make_recruit_hero(player_index, DataHero.from_network_id(hero), \
		coord)


static func make_recruit_unit_from_network(army_coord : Vector2i, \
		unit : String) -> WorldMoveInfo:
	return make_recruit_unit(army_coord, DataUnit.from_network_id(unit))


static func make_build_from_network(city_coord : Vector2i, \
		building_data : String) -> WorldMoveInfo:
	return make_build(city_coord, DataBuilding.from_network_id(building_data))


static func make_end_turn() -> WorldMoveInfo:
	var result : WorldMoveInfo = WorldMoveInfo.new()
	result.move_type = TYPE_END_TURN
	return result


func _to_string() -> String:
	return str(target_tile_coord) + " from " + str(move_source)
