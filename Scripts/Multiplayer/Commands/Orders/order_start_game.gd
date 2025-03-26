class_name OrderStartGame

const COMMAND_NAME = "start_game"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_client(OrderStartGame.process_command)

static func create_packet():
	return {
		"name": COMMAND_NAME,
	}

static func process_command(_client : Client, _params : Dictionary) -> int:
	IM.go_to_main_menu()
	IM.start_game()  # server ordered to start the game
	return OK

