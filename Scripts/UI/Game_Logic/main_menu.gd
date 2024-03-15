extends CanvasLayer

@export var maunual_tester : GeneralTest

@export var map_creator : CanvasLayer

@export var world_setup : WorldSetup  # temporary solution


@export var players : Array[Player]
@export var world_map : WorldMap


func _on_test_game_pressed():
	if world_setup == null:
		print("No game setup")
		return
	
	players = []
	for player_set in world_setup.player_settings:
		var player = player_set.generate_player()
		players.append(player)

	world_map = world_setup.world_map

	start_game()

func start_game():
	toggle_menu_visibility()
	WM.start_world(players, world_setup.world_map)

func toggle_menu_visibility():
	visible = not visible


func _on_test_battle_pressed():
	
	if maunual_tester == null:
		print("No manual tester setup")
		return
	
	if maunual_tester.test_battle():
		toggle_menu_visibility()



func _on_battle_map_creator_pressed():
	IM.draw_mode = true
	map_creator.open_draw_menu()
	toggle_menu_visibility()


func _on_world_map_creator_pressed():
	pass # Replace with function body.
