class_name RequestLogout

const COMMAND_NAME = "logout"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(RequestLogout.process_command)

static func create_packet():
	return {
		"name": COMMAND_NAME,
	}

static func process_command(server : Server, peer : ENetPacketPeer, \
		_params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return OK
	server.sessions.erase(session)
	return OK
