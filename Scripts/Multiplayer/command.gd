class_name Command
extends RefCounted

var server_callback = null
var client_callback = null
var game_callback = null


static func create_on_server(f) -> Command:
	var cmd = Command.new()
	cmd.server_callback = f
	return cmd


static func create_on_client(f) -> Command:
	var cmd = Command.new()
	cmd.client_callback = f
	return cmd


static func create_on_game(f) -> Command:
	var cmd = Command.new()
	cmd.game_callback = f
	return cmd
