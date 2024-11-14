class_name ShareServerSettings

const COMMAND_NAME = "share_server_settings"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_client(ShareServerSettings.process_command)

static func create_packet(content : Dictionary):
	return {
		"name": COMMAND_NAME,
		"content": content
	}

static func process_command(client : Client, params : Dictionary) -> int:
	print("Client - share_server_settings: \n %s" % params)
	if not "content" in params or not params["content"] is Dictionary:
		return FAILED
	var content = params["content"]
	if not client.server_settings_cache:
		client.server_settings_cache = ServerSettings.new()
	client.server_settings_cache.content = content
	return OK
