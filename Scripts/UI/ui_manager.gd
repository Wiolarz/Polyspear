# Singleton - UI
extends Node

var in_game_menu
var main_menu
var map_editor
var unit_editor
var host_lobby
var client_lobby

func _ready():

	IM.init_game_setup() # drut

	in_game_menu = load("res://Scenes/UI/GameMenu.tscn").instantiate()
	main_menu    = load("res://Scenes/UI/MainMenu.tscn").instantiate()
	map_editor   = load("res://Scenes/UI/Editors/MapEditor.tscn").instantiate()
	unit_editor  = load("res://Scenes/UI/Editors/UnitEditor.tscn").instantiate()
	host_lobby   = load("res://Scenes/UI/Lobby/HostLobby.tscn").instantiate()
	client_lobby = load("res://Scenes/UI/Lobby/ClientLobby.tscn").instantiate()

	add_child(main_menu)
	add_child(map_editor)
	add_child(unit_editor)
	add_child(host_lobby)
	add_child(client_lobby)
	add_child(in_game_menu, false, Node.INTERNAL_MODE_BACK)

	_hide_all()


func add_custom_screen(custom_ui : CanvasLayer):
	add_child(custom_ui)
	custom_ui.hide()


func go_to_custom_ui(custom_ui : CanvasLayer):
	_hide_all()
	custom_ui.show()


func _hide_all():
	for c in get_children(true):
		c.hide()


func go_to_main_menu():
	_hide_all()
	main_menu.show()


func go_to_unit_editor():
	_hide_all()
	unit_editor.show()


func go_to_map_editor():
	_hide_all()
	map_editor.open_draw_menu()


func go_to_host_lobby():
	_hide_all()
	host_lobby.show()


func go_to_client_lobby():
	_hide_all()
	client_lobby.show()


func show_in_game_menu():
	in_game_menu.show()


func hide_in_game_menu():
	in_game_menu.hide()
