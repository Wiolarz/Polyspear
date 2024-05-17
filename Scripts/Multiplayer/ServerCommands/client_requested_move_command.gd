class_name ClientRequestedMoveCommand

const COMMAND_NAME = "client_requested_move"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(ClientRequestedMoveCommand.process_command)

static func create_packet(move: MoveInfo):
	return {
		"name": COMMAND_NAME,

		"move_type" : move.move_type,
		"move_source" : move.move_source,
		"target_tile_coord": move.target_tile_coord,
		"summon_unit": DataUnit.get_network_id(move.summon_unit),
	}

static func process_command(_server : Server, _peer : ENetPacketPeer, \
		params : Dictionary) -> int:
	if not "move_type" in params or not params["move_type"] is String:
		return FAILED
	if not "move_source" in params or not params["move_source"] is Vector2i:
		return FAILED
	if not "target_tile_coord" in params or not params["target_tile_coord"] is Vector2i:
		return FAILED
	if not "summon_unit" in params or not params["summon_unit"] is String:
		return FAILED
	var move_info = MakeMoveCommand.create_from(params)
	# TODO check move legality before performing on server
	BM.perform_network_move(move_info)
	return OK

static func create_from(params : Dictionary) -> MoveInfo:
	match params["move_type"]:
		MoveInfo.TYPE_SUMMON:
			return MoveInfo.make_summon( \
				DataUnit.from_network_id(params["summon_unit"]),\
					params["target_tile_coord"])
		MoveInfo.TYPE_MOVE:
			return MoveInfo.make_move(params["move_source"],
					params["target_tile_coord"])
	push_error("move_type not supported: ", params["move_type"])
	return null
