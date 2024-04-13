class_name ClientServerChat
extends Control


@onready var chat_line_edit = \
	$MarginContainer/VBoxContainer/Chat/Writing/ChatMessage


@onready var chat_container = \
	$MarginContainer/VBoxContainer/Chat/LogScroll


func disconnect_from_server():
	IM.client_logout_and_disconnect()


func send_chat_message():
	if chat_line_edit.text.length() == 0:
		return
	IM.send_chat_message(chat_line_edit.text)
	chat_line_edit.text = ""
	scroll_chat_down()


func update_chat():
	chat_container.get_node("Log").text = IM.chat_log


func update_connection_info():
	var label_content = "client does not exist"
	var label = $MarginContainer/VBoxContainer/ConnectionInfo/Log
	var client = IM.get_client()
	if client:
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


func scroll_chat_down():
	chat_container.get_v_scroll_bar().ratio = 1


func _on_send_send_pressed():
	send_chat_message()


func _on_button_disconnect_pressed():
	disconnect_from_server()


func _on_chat_message_text_submitted(new_text):
	send_chat_message()


func _process(_delta : float) -> void:
	update_chat()
	update_connection_info()


