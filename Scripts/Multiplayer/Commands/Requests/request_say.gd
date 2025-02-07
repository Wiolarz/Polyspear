class_name RequestSay

const COMMAND_NAME = "say"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(RequestSay.process_command)

static func create_packet(message : String):
	return {
		"name": COMMAND_NAME,
		"content": message,
	}

static func process_command(server : Server, peer : ENetPacketPeer, \
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
