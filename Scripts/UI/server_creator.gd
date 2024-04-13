class_name ServerCreator
extends Control


var host_menu : HostMenu = null


@onready var server_name_line = \
	$MarginContainer/VBoxContainer/ServerName/LineEdit
@onready var server_address_line = \
	$MarginContainer/VBoxContainer/BindingOptions/IPAddress/LineEdit
@onready var server_port_line = \
	$MarginContainer/VBoxContainer/BindingOptions/Port/LineEdit


func start_server():
	IM.clear_local_chat_log()
	IM.server_listen(get_address(), get_port(), get_username_server())


func get_address():
	return server_address_line.text


func get_port():
	return int(server_port_line.text)


func get_username_server():
	return server_name_line.text


func _ready():
	server_name_line.text = IM.get_random_username()


func _on_button_listen_pressed():
	start_server()


func _on_button_back_pressed():
	host_menu.go_back()
