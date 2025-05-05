class_name Command
extends RefCounted

## This class is a helper for importing all commands (requests and orders) from the directory.
## Function `register` uses this. Probably this will be reworked, because it's too complex.

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
