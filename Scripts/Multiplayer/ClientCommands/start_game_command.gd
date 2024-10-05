class_name StartGameCommand

const COMMAND_NAME = "start_game"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_client(StartGameCommand.process_command)

static func create_packet():
	return {
		"name": COMMAND_NAME,
	}

static func process_command(_client : Client, _params : Dictionary) -> int:
	IM.go_to_main_menu()
	IM.start_game(null, null)
	return OK

