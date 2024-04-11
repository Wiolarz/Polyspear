extends Control

@export var address_default : String = "127.0.0.1"
@export var port_default : int = 12000


func start_server():
	IM.server_listen(get_address(), get_port(), get_username_server())


func stop_server():
	IM.server_close()


func client_connect():
	IM.client_connect_and_login(get_address(), get_port(), get_username_client())


func client_disconnect():
	IM.client_logout_and_disconnect()


func get_address():
	return $VBoxContainer/TextEditAddress.text


func get_port():
	return int($VBoxContainer/TextEditPort.text)


func get_username_client():
	return $VBoxContainer/TextEditUsernameClient.text

func get_username_server():
	return $VBoxContainer/TextEditUsernameServer.text


func update_server_info():
	var label_content = "server does not exist"
	var label = $VBoxContainer/ServerInfo
	var server = IM.get_node_or_null("TheServer")
	if server:
		if server.enet_network:
			label_content = "server is listening\nusername: %s" % server.server_username
			for peer in server.enet_network.get_peers():
				var session = server.get_session_by_peer(peer)
				var connection_state : String = ""
				match peer.get_state():
					ENetPacketPeer.PeerState.STATE_CONNECTED:
						connection_state = "connected"
					ENetPacketPeer.PeerState.STATE_CONNECTING, \
					ENetPacketPeer.PeerState.STATE_ACKNOWLEDGING_CONNECT, \
					ENetPacketPeer.PeerState.STATE_CONNECTION_PENDING, \
					ENetPacketPeer.PeerState.STATE_CONNECTION_SUCCEEDED:
						connection_state = "connecting"
					ENetPacketPeer.PeerState.STATE_DISCONNECT_LATER, \
					ENetPacketPeer.PeerState.STATE_DISCONNECTING, \
					ENetPacketPeer.PeerState.STATE_ACKNOWLEDGING_DISCONNECT, \
					ENetPacketPeer.PeerState.STATE_ZOMBIE:
						connection_state = "disconnecting"
					ENetPacketPeer.PeerState.STATE_DISCONNECTED:
						connection_state = "disconnected"
				if session:
					label_content += "\n%s from %s:%d as %s" % [ connection_state, peer.get_remote_address(), peer.get_remote_port(), session.username ]
				else:
					label_content += "\n%s from %s:%d not logged" % [ connection_state, peer.get_remote_address(), peer.get_remote_port() ]
			for session in server.sessions:
				if session.peer == null:
					label_content += "\ndisconnected session of %s" % session.username
		else:
			label_content = "server is off"
	label.text = label_content


func update_client_info():
	var label_content = "client does not exist"
	var label = $VBoxContainer/ClientInfo
	var client = IM.get_node_or_null("TheClient")
	if client:
		if client.enet_network:
			label_content = "client exists"
			if client.peer:
				var peer = client.peer
				match client.peer.get_state():
					ENetPacketPeer.PeerState.STATE_CONNECTED:
						label_content += "\nconnected to %s %d" % [ peer.get_remote_address(), peer.get_remote_port() ]
					ENetPacketPeer.PeerState.STATE_CONNECTING, ENetPacketPeer.PeerState.STATE_ACKNOWLEDGING_CONNECT:
						label_content += "\nconnecting to %s %d" % [ peer.get_remote_address(), peer.get_remote_port() ]
					_:
						pass
				if client.username != "":
					label_content += "\nlogged as %s" % [ client.username ]
				else:
					label_content += "\nnot logged in"
		else:
			label_content = "client is off"
	label.text = label_content


func _process(_delta : float) -> void:

	update_server_info()
	update_client_info()

	$VBoxContainer/ButtonListen.text = "🔊 server on %s:%d" % [ get_address(), get_port() ]
	$VBoxContainer/ButtonClientConnect.text = "🔌 connect to %s:%d" % [ get_address(), get_port() ]

