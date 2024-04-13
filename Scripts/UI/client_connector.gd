class_name ClientConnector
extends Control


var client_menu : ClientMenu = null


@onready var username_line = \
	$MarginContainer/VBoxContainer/UserName/LineEdit
@onready var server_address_line = \
	$MarginContainer/VBoxContainer/ManualConnection/ConnectionParameters/H/IPAddress/LineEdit
@onready var server_port_line = \
	$MarginContainer/VBoxContainer/ManualConnection/ConnectionParameters/H/Port/LineEdit


func connect_to_server():
	IM.clear_local_chat_log()
	IM.client_connect_and_login(get_address(), get_port(), get_username())


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


func _ready():
	username_line.text = IM.get_random_username()


func _on_button_listen_pressed():
	connect_to_server()


func _on_button_back_pressed():
	client_menu.go_back()
