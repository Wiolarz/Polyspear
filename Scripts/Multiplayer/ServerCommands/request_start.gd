class_name RequestStart

const COMMAND_NAME = "request_start"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(RequestStart.process_command)

static func create_packet():
	return {
		"name": COMMAND_NAME,
	}

static func process_command(server : Server, peer : ENetPacketPeer, \
		params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return FAILED
	if server.settings.all_can_start():
		IM.start_game(null, null)
	return OK
