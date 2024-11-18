class_name MakeMoveCommand

const COMMAND_NAME = "make_move"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_client(MakeMoveCommand.process_command)

static func create_packet(move: MoveInfo):
	var dict = move.to_network_serializable()
	dict["name"] = COMMAND_NAME
	return dict

static func process_command(_client : Client, params : Dictionary) -> int:
	if not "move_type" in params or not params["move_type"] is String:
		return FAILED
	if not "move_source" in params or not params["move_source"] is Vector2i:
		return FAILED
	if not "target_tile_coord" in params or not params["target_tile_coord"] is Vector2i:
		return FAILED
	if not "summon_unit" in params or not params["summon_unit"] is String:
		return FAILED
	var move_info = MakeMoveCommand.create_from(params)
	BM.perform_network_move(move_info)
	return OK

static func create_from(params : Dictionary) -> MoveInfo:
	return MoveInfo.from_network_serializable(params)
