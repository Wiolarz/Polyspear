class_name AllTheCommands
extends Object

#region Server

static func server_login(server : Server, peer : ENetPacketPeer, \
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
		server.send_additional_callbacks_to_logging_client(peer)
		return OK
	server.kick_peer(peer, "username taken by server")
	return OK


static func server_logout(server : Server, peer : ENetPacketPeer, \
		_params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return OK
	server.sessions.erase(session)
	return OK


static func server_join_game(_server : Server, _peer : ENetPacketPeer, \
		_params : Dictionary) -> int:
	return FAILED


static func server_order_game_move(_server : Server, _peer : ENetPacketPeer, \
		_params : Dictionary) -> int:
	return FAILED


static func server_say(server : Server, peer : ENetPacketPeer, \
		params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return FAILED
	if not "content" in params or not params["content"] is String:
		return FAILED
	var message : String = params["content"]
	var author : String  = session.username
	server.broadcast_chat_message(message, author)
	server.get_parent().append_message_to_local_chat_log(message, author)
	return OK

static func server_request_color_cycle(server : Server, peer : ENetPacketPeer, \
		params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return FAILED
	if not "slot" in params or not params["slot"] is int:
		return FAILED
	if not "backwards" in params or not params["backwards"] is bool:
		return FAILED
	var slots = IM.game_setup_info.slots
	var diff : int = 1 if not params["backwards"] else -1
	for index in range(slots.size()):
		var slot = IM.game_setup_info.slots[index]
		if params["slot"] != index:
			continue
		var new_color_index = slots[index].color
		while true:
			new_color_index = (new_color_index + diff) % CFG.TEAM_COLORS.size()
			if new_color_index == slots[index].color: # all colors are taken
				return false
			var is_color_unique = func() -> bool:
				for slot_to_compare in slots:
					if slot_to_compare.color == new_color_index:
						return false
				return true
			if is_color_unique.call():
				slots[index].color = new_color_index
				break
	server.broadcast_full_game_setup(IM.game_setup_info)
	IM.game_setup_info_changed.emit()
	return OK

#endregion


#region Client

static func client_replay_game_move(_client : Client, \
		_params : Dictionary) -> int:
	return FAILED


static func client_set_session(client : Client, params : Dictionary) -> int:
	if not "username" in params or not params["username"] is String:
		return FAILED
	var username : String = params["username"]
	client.username = username
	print("server sent us that we are called %s" % username)
	return OK


static func client_kicked(client : Client, params : Dictionary) -> int:
	if "reason" in params and params["reason"] is String:
		print("kicked from server with reason: %s" % params["reason"])
	else:
		print("kicked from server without good reason")
	client.close()
	return OK


static func client_chat(client : Client, params : Dictionary) -> int:
	if client.username == "":
		return FAILED
	if not "content" in params or not params["content"] is String:
		return FAILED
	if not "author" in params or not params["author"] is String:
		return FAILED
	var message = params["content"]
	var author = params["author"]
	IM.append_message_to_local_chat_log(message, author)
	return OK

static func client_fill_game_setup(client : Client, params : Dictionary) -> int:
	if not "setup" in params or not params["setup"] is Dictionary:
		return FAILED
	var setup = GameSetupInfo.from_dictionary(params["setup"], \
		IM.get_current_name())
	IM.game_setup_info = setup
	IM.game_setup_info_changed.emit()
	print("Client: %s" % params)
	return OK

#endregion
