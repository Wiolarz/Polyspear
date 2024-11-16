class_name ServerInfoAndChat
extends Control

"""
UI - Server Admin tools + chat box
"""


var host_menu : HostMenu = null

@onready var chat_line_edit = \
	$MarginContainer/VBoxContainer/Chat/Writing/ChatMessage

@onready var chat_container : ScrollContainer = \
	$MarginContainer/VBoxContainer/Chat/LogScroll

@onready var server_status_label = \
	$MarginContainer/VBoxContainer/ServerInfo/Log

@onready var external_ip_poll_button = \
	$MarginContainer/VBoxContainer/ButtonsRow2/ButtonPollIp

@onready var external_ip_edit = \
	$MarginContainer/VBoxContainer/ButtonsRow2/ExternalIpLineEdit

@onready var external_port_edit = \
	$MarginContainer/VBoxContainer/ButtonsRow3/ExternalPortLineEdit


func _ready():
	external_ip_poll_button.text = \
		"Fetch external ip by\ncalling '%s'" % [CFG.FETCH_EXTERNAL_IP_GET_URL]
	external_ip_edit.text = NET.server.server_external_address
	external_port_edit.text = str(NET.server.enet_network.get_local_port())

func _process(_delta):
	update_server_info()
	update_chat()


#region Chat

func update_chat():
	chat_container.get_node("Log").text = NET.chat_log


func scroll_chat_down():
	await get_tree().create_timer(0.1).timeout # needs time to update sizes
	chat_container.get_v_scroll_bar().ratio = 1


func send_chat_message():
	if chat_line_edit.text.length() == 0:
		return
	NET.send_chat_message(chat_line_edit.text)
	chat_line_edit.text = ""
	update_chat()
	scroll_chat_down()


func _on_button_send_pressed():
	send_chat_message()


func _on_chat_message_text_submitted(_new_text):
	# _new_text - default Godot LineEdit requires a single variable
	send_chat_message()

#endregion


#region Server Admin Buttons

func stop_server():
	NET.server_close()


func kick_all_players():
	NET.server_kick_all()


func _on_button_stop_pressed():
	var login = NET.server.server_username
	stop_server()
	host_menu.refresh_after_connection_change()
	await PolyApi.delete_server(login)


func _on_button_kick_all_pressed():
	kick_all_players()

#endregion


func update_server_info():
	server_status_label.text = get_server_status_string()


func get_server_status_string() -> String:
	if not NET.server:
		return "server is turned off"

	if not NET.server.enet_network:
		return "connection is not active"

	var result = ""
	result += "host login: %s\n" % NET.server.server_username
	if not CFG.player_options.streamer_mode:
		result += "LOCAL address %s:%d\n"% \
			[NET.server.server_local_address,
				NET.server.enet_network.get_local_port()]
	result += "peers:\n"
	var has_peers := false
	for peer in NET.server.enet_network.get_peers():
		result += describe_peer(peer) + "\n"
		has_peers = true
	for session in NET.server.sessions:
		if session.peer == null:
			result += " - %s - session disconnected\n" % session.username
			has_peers = true
	if not has_peers:
		result += " - <no peers>"
	return result


func describe_peer(peer : ENetPacketPeer):
	var connection_state : String = describe_peer_state(peer)
	var session = NET.server.get_session_by_peer(peer)
	var info : String
	if not session:
		info = "- (no session) [%s]" % [ \
			connection_state]
	else:
		info = "- %s [%s]" % [ \
			session.username, connection_state]
	if not CFG.player_options.streamer_mode:
		info += " %s:%d" % [peer.get_remote_address(), peer.get_remote_port()]
	return info


func describe_peer_state(peer:ENetPacketPeer) -> String:
	match peer.get_state():
		ENetPacketPeer.PeerState.STATE_CONNECTED:
			return "connected"
		ENetPacketPeer.PeerState.STATE_CONNECTING, \
		ENetPacketPeer.PeerState.STATE_ACKNOWLEDGING_CONNECT, \
		ENetPacketPeer.PeerState.STATE_CONNECTION_PENDING, \
		ENetPacketPeer.PeerState.STATE_CONNECTION_SUCCEEDED:
			return "connecting"
		ENetPacketPeer.PeerState.STATE_DISCONNECT_LATER, \
		ENetPacketPeer.PeerState.STATE_DISCONNECTING, \
		ENetPacketPeer.PeerState.STATE_ACKNOWLEDGING_DISCONNECT, \
		ENetPacketPeer.PeerState.STATE_ZOMBIE:
			return "disconnecting"
		ENetPacketPeer.PeerState.STATE_DISCONNECTED:
			return "disconnected"
		_:
			return "unknown (%d)" % peer.get_state()


func _on_button_poll_ip_pressed():
	var external_ip = await NET.fetch_external_address_guess()
	if NET.server:
		NET.server.server_external_address = external_ip
		external_ip_edit.text = external_ip


func _on_is_public_check_box_toggled(toggled_on):
	if toggled_on:
		if NET.server.server_external_address == "-needs fetch-":
			await _on_button_poll_ip_pressed()

		var server_description := PolyApi.ServerDescription.new({
			login = NET.server.server_username,
			address = external_ip_edit.text,
			port = external_port_edit.text as int,
			description = "normal server"
		})
		await PolyApi.post_server(server_description)
	else:
		await PolyApi.delete_server(NET.server.server_username)
