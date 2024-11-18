class_name LobbySetTeamCommand

const COMMAND_NAME = "lobby_set_team"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(LobbySetTeamCommand.process_command)

static func create_packet(slot_index : int, team_index : int):
	return {
		"name": COMMAND_NAME,

		"slot_index": slot_index,
		"team_index": team_index
	}

static func process_command(server : Server, peer : ENetPacketPeer, \
		params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return FAILED

	if not "slot_index" in params or not params["slot_index"] is int:
		return FAILED
	var slot_index = params["slot_index"] as int

	if not "team_index" in params or not params["team_index"] is int:
		return FAILED
	var team_index = params["team_index"] as int

	if not IM.game_setup_info.has_slot(slot_index):
		return FAILED

	IM.game_setup_info.set_team(slot_index, team_index)
	IM.game_setup_info_changed.emit()
	server.broadcast_full_game_setup(IM.game_setup_info)
	return OK

