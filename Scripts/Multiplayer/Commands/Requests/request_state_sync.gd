class_name RequestStateSync

const COMMAND_NAME = "state_sync"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(RequestStateSync.process_command)

static func create_packet():
	return {
		"name": COMMAND_NAME,
	}

static func process_command(server : Server, peer : ENetPacketPeer, \
		_params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return FAILED
	server.send_full_state_sync(peer)
	return OK
