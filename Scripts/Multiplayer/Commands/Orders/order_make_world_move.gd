class_name OrderMakeWorldMove


const COMMAND_NAME = "make_world_move"


static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_client(OrderMakeWorldMove.process_command)


static func create_packet(move: WorldMoveInfo):
	var packet : Dictionary = {
		"name": COMMAND_NAME,

		"move_type": move.move_type,
	}
	if move.move_type == WorldMoveInfo.TYPE_TRAVEL:
		packet["move_source"] = move.move_source
		packet["target_tile_coord"] = move.target_tile_coord
	if move.move_type == WorldMoveInfo.TYPE_RECRUIT_HERO:
		packet["target_tile_coord"] = move.target_tile_coord
		packet["player_index"] = move.recruit_hero_info.player_index
		packet["data_hero"] = \
			DataHero.get_network_id(move.recruit_hero_info.data_hero)
	if move.move_type == WorldMoveInfo.TYPE_RECRUIT_UNIT:
		packet["move_source"] = move.move_source
		packet["target_tile_coord"] = move.target_tile_coord
		packet["data_unit"] = DataUnit.get_network_id(move.data as DataUnit)
	if move.move_type == WorldMoveInfo.TYPE_BUILD:
		packet["target_tile_coord"] = move.target_tile_coord
		packet["data_building"] = DataBuilding.get_network_id(move.data as DataBuilding)
	return packet


static func process_command(_client : Client, params : Dictionary) -> int:
	if not "move_type" in params or not params["move_type"] is String:
		return FAILED
	match params["move_type"]:
		WorldMoveInfo.TYPE_TRAVEL:
			if not "move_source" in params or \
					not params["move_source"] is Vector2i:
				return FAILED
			if not "target_tile_coord" in params or \
					not params["target_tile_coord"] is Vector2i:
				return FAILED
		WorldMoveInfo.TYPE_RECRUIT_HERO:
			if not "player_index" in params or \
					not params["player_index"] is int:
				return FAILED
			if not "data_hero" in params or \
					not params["data_hero"] is String:
				return FAILED
			if not "target_tile_coord" in params or \
					not params["target_tile_coord"] is Vector2i:
				return FAILED
		WorldMoveInfo.TYPE_RECRUIT_UNIT:
			if not "move_source" in params or \
					not params["move_source"] is Vector2i:
				return FAILED
			if not "target_tile_coord" in params or \
					not params["target_tile_coord"] is Vector2i:
				return FAILED
			if not "data_unit" in params or \
					not params["data_unit"] is String:
				return FAILED
		WorldMoveInfo.TYPE_BUILD:
			if not "target_tile_coord" in params or \
					not params["target_tile_coord"] is Vector2i:
				return FAILED
			if not "data_building" in params or \
					not params["data_building"] is String:
				return FAILED
		WorldMoveInfo.TYPE_END_TURN:
			pass # end turn has no parameters
		_:
			return FAILED
	var world_move_info = OrderMakeWorldMove.create_from(params)
	WM.perform_network_move(world_move_info)
	return OK


static func create_from(params : Dictionary) -> WorldMoveInfo:
	match params["move_type"]:
		WorldMoveInfo.TYPE_TRAVEL:
			return WorldMoveInfo.make_world_travel(params["move_source"],
					params["target_tile_coord"])
		WorldMoveInfo.TYPE_RECRUIT_HERO:
			return WorldMoveInfo.make_recruit_hero_from_network(
					params["player_index"],
					params["data_hero"], params["target_tile_coord"])
		WorldMoveInfo.TYPE_RECRUIT_UNIT:
			return WorldMoveInfo.make_recruit_unit_from_network(
					params["move_source"],
					params["target_tile_coord"], params["data_unit"])
		WorldMoveInfo.TYPE_BUILD:
			return WorldMoveInfo.make_build_from_network(
					params["target_tile_coord"], params["data_building"])
		WorldMoveInfo.TYPE_END_TURN:
			return WorldMoveInfo.make_end_turn()
	push_error("move_type not supported: ", params["move_type"])
	return null
