class_name OrderSetSession

const COMMAND_NAME = "set_session"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_client(OrderSetSession.process_command)

static func create_packet(login : String):
	return {
		# this is the name of the command client should do on its side
		"name": COMMAND_NAME,
		# this is the content
		"username": login,
	}

static func process_command(client : Client, params : Dictionary) -> int:
	if not "username" in params or not params["username"] is String:
		return FAILED
	var username : String = params["username"]
	client.username = username
	print("server sent us that we are called %s" % username)
	return OK
