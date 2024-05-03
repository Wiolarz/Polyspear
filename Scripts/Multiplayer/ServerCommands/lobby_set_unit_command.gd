class_name LobbySetUnitCommand

const COMMAND_NAME = "lobby_set_unit"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(LobbySetUnitCommand.process_command)

static func create_packet(slot_index:int, unit_index:int, unit_data:DataUnit):
	return {
		"name": COMMAND_NAME,

		"slot_index": slot_index,
		"unit_index": unit_index,
		"unit_data" : DataUnit.get_network_id(unit_data),
	}

static func process_command(server : Server, peer : ENetPacketPeer, \
		params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return FAILED

	if not "slot_index" in params or not params["slot_index"] is int:
		return FAILED
	var slot_index = params["slot_index"] as int

	if not "unit_index" in params or not params["unit_index"] is int:
		return FAILED
	var unit_index = params["unit_index"] as int

	if not "unit_data" in params or not params["unit_data"] is String:
		return FAILED
	var unit_data = DataUnit.from_network_id(params["unit_data"])

	if not IM.game_setup_info.has_slot(slot_index):
		return FAILED

	IM.game_setup_info.set_unit(slot_index, unit_index, unit_data)
	IM.game_setup_info_changed.emit()
	server.broadcast_full_game_setup(IM.game_setup_info)
	return OK

