class_name RequestLogin

const COMMAND_NAME = "login"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(RequestLogin.process_command)

static func create_packet(desired_username : String):
	return {
		"name": COMMAND_NAME,
		"username": desired_username,
	}

static func process_command(server : Server, peer : ENetPacketPeer, \
		params : Dictionary) -> int:
	if not "username" in params or not params["username"] is String:
		return FAILED
	if server.get_session_by_peer(peer) != null:
		server.kick_peer(peer, "was logged in already")
		return OK
	var username : String = params["username"]
	var session = server.create_or_get_session(username)
	if session != null:
		var previous_peer : ENetPacketPeer = \
		  server.connect_peer_to_session(peer, session)
		var response_packet = OrderSetSession.create_packet(username)
		print("created a session for user %s" % username)
		server.send_to_peer(peer, response_packet)
		if previous_peer:
			print("kicking previous user of this session because of second " +\
				"login")
			server.kick_peer(previous_peer,
				"logged to this account from somewhere else")
		server.send_additional_callbacks_to_logging_client(peer)
		return OK
	server.kick_peer(peer, "username taken by server")
	return OK
