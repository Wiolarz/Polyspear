extends CanvasLayer

@export var maunual_tester : GeneralTest

@export var map_creator : CanvasLayer
@export var unit_editor : CanvasLayer

@export var battle_setup : CanvasLayer
@export var world_setup : WorldSetup  # temporary solution

@export var world_map : WorldMap

@onready var main_page : Control = $Control


func toggle_menu_visibility():
	visible = not visible


func clear_main_menu(): #TODO needs refactor
	main_page.visible = false
	for child in get_children():
		if (child.name == "Control"):
			continue
		remove_child(child)


func go_to_main_menu():
	clear_main_menu()
	main_page.visible = true


#region Manual Tests

func _on_test_world_pressed():
	# World map test
	assert(maunual_tester != null, "No manual tester setup")

	maunual_tester.test_world()
	toggle_menu_visibility()

#endregion


#region Editors

func _on_editors_menu_id_pressed(id):
	match id:
		0: _on_map_creator_pressed()
		1: _on_unit_editor_pressed()
		_: pass


func _on_unit_editor_pressed():
	unit_editor.visible = !unit_editor.visible
	toggle_menu_visibility()


func _on_map_creator_pressed():
	IM.draw_mode = true
	map_creator.open_draw_menu()
	toggle_menu_visibility()

#endregion


#region Gameplay

func _on_battle_setup_pressed():
	battle_setup.visible = !battle_setup.visible
	toggle_menu_visibility()

#endregion


#region Multiplayer

func go_to_host_lobby():
	clear_main_menu()
	var host_menu = get_node_or_null("HostMenu")
	if host_menu:
		host_menu.visible = true
		return
	host_menu = load("res://Scenes/UI/HostMenu.tscn").instantiate()
	add_child(host_menu)
	host_menu.name = "HostMenu"
	host_menu.visible = true


func go_to_client_lobby():
	clear_main_menu()
	var client_menu = get_node_or_null("ClientMenu")
	if client_menu:
		client_menu.visible = true
		return
	client_menu = load("res://Scenes/UI/ClientMenu.tscn").instantiate()
	add_child(client_menu)
	client_menu.name = "ClientMenu"
	client_menu.visible = true


func _on_host_pressed():
	go_to_host_lobby()


func _on_join_pressed():
	go_to_client_lobby()

#endregion
