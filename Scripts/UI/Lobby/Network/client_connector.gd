class_name ClientConnector
extends Control


"""
UI - smalll menu where you connect to a server
"""

var client_menu : ClientMenu = null


@onready var username_line = \
	$MarginContainer/VBoxContainer/UserName/LineEdit
@onready var server_address_line = \
	$MarginContainer/VBoxContainer/ManualConnection/ConnectionParameters/H/IPAddress/LineEdit
@onready var server_port_line = \
	$MarginContainer/VBoxContainer/ManualConnection/ConnectionParameters/H/Port/LineEdit


func _ready():
	username_line.text = CFG.get_username()
	server_address_line.text = CFG.player_options.lastRemoteHostAddress
	server_port_line.text = str(CFG.player_options.lastRemoteHostPort)


func get_address():
	var server_on_list_selected : bool = false
	if server_on_list_selected:
		return "" # address of selected server
	return server_address_line.text


func get_port():
	var server_on_list_selected : bool = false
	if server_on_list_selected:
		return 0 # port of selected server
	return int(server_port_line.text)


func get_username():
	return username_line.text


func connect_to_server():
	CFG.set_defaults_for_joining(get_address(), get_port(), get_username())
	NET.clear_local_chat_log()
	NET.client_connect_and_login(get_address(), get_port(), get_username())


func _on_button_listen_pressed():
	connect_to_server()


func _on_button_back_pressed():
	client_menu.go_back()


func _on_refresh_servers_button_pressed():
	var servers_box = $MarginContainer/VBoxContainer/ServerList/ColorRect/VBoxContainer
	for c in servers_box.get_children():
		servers_box.remove_child(c)
		c.queue_free()
	var loading_label := Label.new()
	loading_label.text = "loading..."
	servers_box.add_child(loading_label)
	var servers = await PolyApi.get_servers_list()
	servers_box.remove_child(loading_label)
	loading_label.queue_free()
	for s in servers:
		var b := Button.new()
		b.text = str(s)
		b.pressed.connect(func on_click():
			$MarginContainer/VBoxContainer/ManualConnection/ConnectionParameters/H/IPAddress/LineEdit \
					.text = s.address
			$MarginContainer/VBoxContainer/ManualConnection/ConnectionParameters/H/Port/LineEdit \
					.text = str(s.port)
			($MarginContainer as ScrollContainer).scroll_vertical = 0
		)
		servers_box.add_child(b)
