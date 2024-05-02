class_name ServerInfoAndChat
extends Control

"""
UI - Server Admin tools + chat box
"""


var host_menu : HostMenu = null

@onready var chat_line_edit = \
	$MarginContainer/VBoxContainer/Chat/Writing/ChatMessage

@onready var chat_container = \
	$MarginContainer/VBoxContainer/Chat/LogScroll


func _process(_delta):
	update_server_info()
	update_chat()


#region Chat
func update_chat():
	chat_container.get_node("Log").text = NET.chat_log


func scroll_chat_down():
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
	stop_server()
	host_menu.refresh_after_connection_change()


func _on_button_kick_all_pressed():
	kick_all_players()

#endregion


func update_server_info():
	var label_content = "server does not exist"
	var label = $MarginContainer/VBoxContainer/ServerInfo/Log
	var server = IM.get_node_or_null("TheServer")
	if server:
		if server.enet_network:
			label_content = \
				"server is listening\nusername: %s" % server.server_username
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
					label_content += "\n%s from %s:%d as %s" % [ \
						connection_state, peer.get_remote_address(), \
						peer.get_remote_port(), session.username ]
				else:
					label_content += "\n%s from %s:%d not logged" % [ \
						connection_state, peer.get_remote_address(), \
						peer.get_remote_port() ]
			for session in server.sessions:
				if session.peer == null:
					label_content += \
						"\ndisconnected session of %s" % session.username
		else:
			label_content = "server is off"
	label.text = label_content
