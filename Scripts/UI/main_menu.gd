extends CanvasLayer

@export var maunual_tester : GeneralTest

@export var map_creator : CanvasLayer
@export var unit_editor : CanvasLayer

@export var battle_setup : CanvasLayer
@export var world_setup : WorldSetup  # temporary solution

@export var world_map : WorldMap


func _on_test_game_pressed():
	assert(world_setup != null, "No game setup")

	var players : Array[Player] = []
	for player_set in world_setup.player_settings:
		var player = player_set.create_player()
		players.append(player)

	world_map = world_setup.world_map

	start_game(players)

func start_game(players:Array[Player] = []):
	toggle_menu_visibility()
	IM.players = players
	WM.start_world(world_setup.world_map)

func toggle_menu_visibility():
	visible = not visible



func _on_map_creator_pressed():
	IM.draw_mode = true
	map_creator.open_draw_menu()
	toggle_menu_visibility()


#region Tests

func _on_test_battle_pressed():
	assert(maunual_tester != null, "No manual tester setup")

	
	maunual_tester.test_battle()
	toggle_menu_visibility()



func _on_test_world_pressed():
	assert(maunual_tester != null, "No manual tester setup")

	maunual_tester.test_world()
	toggle_menu_visibility()



#endregion


func _on_unit_editor_pressed():
	unit_editor.visible = !unit_editor.visible
	toggle_menu_visibility()


func _on_test_battle_with_setup_pressed():
	battle_setup.visible = !battle_setup.visible
	toggle_menu_visibility()
