extends Node

class_name Client

var username : String = ""
var peer : ENetPacketPeer = null
@onready var enet_network : ENetConnection = null
var send_queue : Array = []


var incoming_commands : Dictionary = {
	"set_session": Command.create_on_client(AllTheCommands.set_session),
	"kicked": Command.create_on_client(AllTheCommands.kicked),
	"replay_game_move": Command.create_on_client(AllTheCommands.replay_game_move),
}


func connect_to_server(address : String, port : int):
	print("Requested connection to a server: %s:%d" % [ address, port ])
	if enet_network != null:
		print("Client was already connected -- disconnecting first")
		close()
	enet_network = ENetConnection.new()
	var error : Error = enet_network.create_host(1, 1)
	if error != OK:
		print("Could not create host")
	peer = enet_network.connect_to_host(address, port, 1, 0)
	if peer == null:
		print("Could not connect client")
		enet_network = null
		peer = null
		return
	print("No errors")


func reset_session() -> void:
	username = ""


func queue_message_to_server(command_dictionary : Dictionary):
	if not command_dictionary is Dictionary:
		return
	var content : PackedByteArray = var_to_bytes(command_dictionary)
	send_queue.append(content)


func send_message_to_server_immediately(command_dictionary : Dictionary):
	var content : PackedByteArray = var_to_bytes(command_dictionary)
	peer.send(0, content, ENetPacketPeer.FLAG_RELIABLE)
	enet_network.flush()


func queue_login(username : String):
	var packet : Dictionary = {
		"name": "login",
		"username": username,
	}
	queue_message_to_server(packet)


func logout_if_needed():
	if username == "":
		return
	var packet : Dictionary = {
		"name": "logout"
	}
	username = ""
	send_message_to_server_immediately(packet)
	# TODO consider unrealiable packet send here


func close():
	print("Requested client disconnect")
	if enet_network == null:
		print("Client was not connected")
		return
	enet_network.flush()
	if peer:
		peer.peer_disconnect_later()
	enet_network.flush()
	enet_network.destroy()
	enet_network = null
	peer = null
	print("Client disconnected")


func roll() -> void:
	var broken : bool = false
	while true:
		if not enet_network:
			return
		var event : Array = enet_network.service()

		var type : ENetConnection.EventType = event[0]
		var peer : ENetPacketPeer = event[1]
		var data = event[2]
		var channel : int = event[3]

		match type:
			ENetConnection.EventType.EVENT_ERROR:
				print("Error at server service -- server will be destroyed")
				broken = true
				break
			ENetConnection.EventType.EVENT_NONE:
				break
			ENetConnection.EventType.EVENT_CONNECT:
				print("Connected to server")
			ENetConnection.EventType.EVENT_DISCONNECT:
				print("Disconnected")
				peer = null
				enet_network = null
				return
			ENetConnection.EventType.EVENT_RECEIVE:
				var packet : PackedByteArray = peer.get_packet()
				if channel != 0:
					print("Server sent something on different channel than 0 -- ignoring")
				var decoded = MultiCommon.decode_packet(packet)
				if not decoded:
					print("Server sent something not being a command")
					break
				var command_name = decoded["name"]
				print("server sent us command %s" % [ command_name ])
				if not command_name in incoming_commands:
					print("server sent us unknown command %s" % [ command_name ])
					break
				var command = incoming_commands[command_name]
				if command.client_callback:
					var result = (command.client_callback).call(self, decoded)
					if result != 0:
						print("server sent us %s command, but we couldn't process it well" % [ command_name ])
					break
					print("command processed")
	if peer != null and peer.get_state() == ENetPacketPeer.STATE_CONNECTED:
		while send_queue.size() != 0:
			var content = send_queue[0]
			send_queue.remove_at(0)
			peer.send(0, content, ENetPacketPeer.FLAG_RELIABLE)
	if broken:
		close()


func _process(delta):
	roll()
