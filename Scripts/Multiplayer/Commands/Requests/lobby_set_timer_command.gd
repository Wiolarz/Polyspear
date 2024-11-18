class_name LobbySetTimerCommand

const COMMAND_NAME = "lobby_set_timer"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(LobbySetTimerCommand.process_command)

static func create_packet(slot_index : int, reserve_sec : int, increment_sec : int):
	return {
		"name": COMMAND_NAME,

		"slot_index": slot_index,
		"reserve_sec": reserve_sec,
		"increment_sec": increment_sec,
	}

static func process_command(server : Server, peer : ENetPacketPeer, \
		params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return FAILED

	if not "slot_index" in params or not params["slot_index"] is int:
		return FAILED
	var slot_index = params["slot_index"] as int

	if not "reserve_sec" in params or not params["reserve_sec"] is int:
		return FAILED
	var reserve_sec = params["reserve_sec"] as int

	if not "increment_sec" in params or not params["increment_sec"] is int:
		return FAILED
	var increment_sec = params["increment_sec"] as int

	if not IM.game_setup_info.has_slot(slot_index):
		return FAILED
	
	IM.game_setup_info.set_timer(slot_index, reserve_sec, increment_sec)

	IM.game_setup_info_changed.emit()
	server.broadcast_full_game_setup(IM.game_setup_info)
	return OK

