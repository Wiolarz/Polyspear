class_name AllTheCommands


static func login(server : Server, peer, params : Dictionary) -> int:
	if not "username" in params or not params["username"] is String:
		return -1 # TODO consider better convention
	var username : String = params["username"]
	var session = server.create_session(username)
	var response_packet : Dictionary = {}
	if session != null:
		server.connect_peer_to_session(peer, session)
		response_packet = {
			"name": "set_session", # name of the command client should do on its side
			"username": session.username, # this is the content
		}
	else:
		response_packet = {
			"name": "kicked",
			"reason": "username taken by server",
		}
	print("created a session for user %s" % username)
	server.send_to_peer(peer, response_packet)
	return 0


static func logout(server : Server, peer, params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return 0
	server.sessions.erase(session)
	return 0


static func join_game(server : Server, peer, params : Dictionary) -> int:
	return -1


static func order_game_move(server : Server, peer, params : Dictionary) -> int:
	return -1


static func replay_game_move(client : Client, params : Dictionary) -> int:
	return -1


static func set_session(client : Client, params : Dictionary) -> int:
	if not "username" in params or not params["username"] is String:
		return -1
	var username : String = params["username"]
	client.username = username
	print("server sent us that we are called %s" % username)
	return 0


static func kicked(client : Client, params : Dictionary) -> int:
	client.close()
	client.reset_session()
	return 0
