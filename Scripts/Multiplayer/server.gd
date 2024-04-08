class_name Server
extends Node


class Session:
	var username : String = ""
	var peer : ENetPacketPeer = null
	var seats : Dictionary = {} # Dictionary[int -> int]


var incoming_commands : Dictionary = { # Dictionary[String -> Command]
	"login": Command.create_on_server(AllTheCommands.login),
	"logout": Command.create_on_server(AllTheCommands.logout),
	"join_game": Command.create_on_server(AllTheCommands.join_game),
	"order_game_move": Command.create_on_server(AllTheCommands.order_game_move),
}


var server_username : String = ""
@onready var sessions : Array = [] # Array[Session] TODO other structure for speed
@onready var enet_network : ENetConnection = null

#region Connection

func listen(address : String, port : int, username : String):
	print("Requested server to listen at %s:%d" % [ address, port ])
	if enet_network != null:
		print("Server was listening -- stopping it first")
		close()
	enet_network = ENetConnection.new()
	var error = enet_network.create_host_bound(address, port, 32, 0, 0, 0)
	if error == OK:
		server_username = username
		print("Server successfully started to listen on %s:%d" % [ address, port ])
		return
	print("Could not start to listen: %d" % error)
	enet_network.destroy()
	enet_network = null


func get_session_by_username(username : String) -> Session:
	if username == server_username:
		return null
	for session in sessions:
		if session.username == username:
			return session
	return null


func get_session_by_peer(peer : ENetPacketPeer) -> Session:
	for session in sessions:
		if session.peer == peer:
			return session
	return null


func create_or_get_session(username : String) -> Session:
	if username == server_username:
		return null
	var session : Session = get_session_by_username(username)
	if session != null:
		return session
	session = Session.new()
	sessions.append(session)
	session.username = username
	return session


func connect_peer_to_session(peer : ENetPacketPeer, session : Session):
	var previous_peer : ENetPacketPeer = session.peer
	session.peer = peer
	return previous_peer


func detach_session(session : Session):
	session.peer = null


func drop_session(session : Session):
	sessions.erase(session)


func kick_peer(peer : ENetPacketPeer, reason : String) -> void:
	var session = get_session_by_peer(peer)
	if session:
		sessions.erase(session)
	var message = {
		"name": "kicked",
		"reason": reason,
	}
	send_to_peer(peer, message)
	peer.peer_disconnect_later()


func close():
	print("Stopping server")
	if enet_network == null:
		print("Server was not listening")
		return
	for session : Session in sessions:
		detach_session(session)
	enet_network.destroy()
	enet_network = null
	sessions.clear()
	server_username = ""
	print("Server stopped")

#endregion


#region Communication

func send_to_peer(peer : ENetPacketPeer, command_dictionary : Dictionary):
	if not command_dictionary is Dictionary:
		return
	var content : PackedByteArray = var_to_bytes(command_dictionary)
	peer.send(0, content, ENetPacketPeer.FLAG_RELIABLE)


func roll() -> void:
	var broken : bool = false
	if not enet_network:
		return
	while true:
		var event : Array = enet_network.service()

		var type : ENetConnection.EventType = event[0]
		var peer : ENetPacketPeer = event[1]
		#var data = event[2]
		var channel : int = event[3]

		match type:
			ENetConnection.EventType.EVENT_ERROR:
				print("Error at server service -- server will be destroyed")
				broken = true
				break
			ENetConnection.EventType.EVENT_NONE:
				break
			ENetConnection.EventType.EVENT_CONNECT:
				print("New connection arrived %d" % peer.get_instance_id())
			ENetConnection.EventType.EVENT_DISCONNECT:
				var id : int = peer.get_instance_id()
				print("Connection %x disconnected" % id)
				var session = get_session_by_peer(peer)
				if session:
					detach_session(session)
			ENetConnection.EventType.EVENT_RECEIVE:
				var packet : PackedByteArray = peer.get_packet()
				if channel != 0:
					print("Peer %x sent something on different channel than 0 -- ignoring" % peer.get_instance_id())
					break
				var decoded = MultiCommon.decode_packet(packet)
				if not decoded:
					print("Peer %x sent something not being a command" % peer.get_instance_id())
					break
				var command_name = decoded["name"]
				print("peer %x sent us command %s" % [ peer.get_instance_id(), command_name ])
				if not command_name in incoming_commands:
					print("peer %x sent us unknown command %s" % [ peer.get_instance_id(), command_name ])
					break
				var command = incoming_commands[command_name]
				if command.server_callback:
					var result = (command.server_callback).call(self, peer, decoded)
					if result != 0:
						print("Peer %x sent us %s command, but we couldn't process it well" % [ peer.get_instance_id(), command_name ])
					print("command processed")
				if command.game_callback:
					pass
	if broken:
		close()


func _process(_delta):
	roll()

#endregion
