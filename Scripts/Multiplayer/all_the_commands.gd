class_name AllTheCommands
extends Object

#region Server

static func login(server : Server, peer : ENetPacketPeer, params : Dictionary) -> int:
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
		var response_packet = {
			# this is the name of the command client should do on its side
			"name": "set_session",
			# this is the content
			"username": session.username,
		}
		print("created a session for user %s" % username)
		server.send_to_peer(peer, response_packet)
		if previous_peer:
			print("kicking previous user of this session because of second " +\
				"login")
			server.kick_peer(previous_peer,
				"logged to this account from somewhere else")
		return OK
	server.kick_peer(peer, "username taken by server")
	return OK


static func logout(server : Server, peer : ENetPacketPeer, _params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return OK
	server.sessions.erase(session)
	return OK


static func join_game(_server : Server, _peer : ENetPacketPeer, _params : Dictionary) -> int:
	return FAILED


static func order_game_move(_server : Server, _peer : ENetPacketPeer, _params : Dictionary) -> int:
	return FAILED

#endregion


#region Client

static func replay_game_move(_client : Client, _params : Dictionary) -> int:
	return FAILED


static func set_session(client : Client, params : Dictionary) -> int:
	if not "username" in params or not params["username"] is String:
		return FAILED
	var username : String = params["username"]
	client.username = username
	print("server sent us that we are called %s" % username)
	return OK


static func kicked(client : Client, params : Dictionary) -> int:
	if "reason" in params and params["reason"] is String:
		print("kicked from server with reason: %s" % params["reason"])
	else:
		print("kicked from server without good reason")
	client.close()
	return OK

#endregion
