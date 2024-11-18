class_name KickedCommand

const COMMAND_NAME = "kicked"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_client(KickedCommand.process_command)

static func create_packet(reason : String):
	return {
		"name": COMMAND_NAME,
		"reason": reason,
	}

static func process_command(client : Client, params : Dictionary) -> int:
	if "reason" in params and params["reason"] is String:
		print("kicked from server with reason: %s" % params["reason"])
	else:
		print("kicked from server without good reason")
	client.close()
	return OK
