class_name StartGameCommand

const COMMAND_NAME = "start_game"

static func create_packet():
	return {
		"name": COMMAND_NAME,
	}

static func process_command(_client : Client, _params : Dictionary) -> int:
	IM.start_game()
	return OK

