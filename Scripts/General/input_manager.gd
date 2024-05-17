# Singleton - IM
# rename to GameManager
extends Node


## notifies when `game_setup_info` is modified
signal game_setup_info_changed

var game_setup_info : GameSetupInfo

var players : Array[Player] = []

## flag for MAP EDITOR
var draw_mode : bool = false


func init_game_setup():
	game_setup_info = GameSetupInfo.create_empty()


#endregion

#region Game setup

func get_world_maps_list() -> Array[String]:
	return FileSystemHelpers.list_files_in_folder(CFG.WORLD_MAPS_PATH)

func get_battle_maps_list() -> Array[String]:
	return FileSystemHelpers.list_files_in_folder(CFG.BATTLE_MAPS_PATH)


## starts game based on game_setup_info
func start_game():
	for p in players:
		p.queue_free()
	players = []
	for s in game_setup_info.slots:
		var p := Player.create(s)
		players.append(p)
		add_child(p)

	UI.ensure_camera_is_spawned()

	if game_setup_info.is_in_mode_world():
		_start_game_world()
		B_GRID.position.x = WM.get_bounds_global_position().end.x + CFG.MAPS_OFFSET_X
		UI.set_camera(E.CameraPosition.WORLD)
	if game_setup_info.is_in_mode_battle():
		_start_game_battle()
		UI.set_camera(E.CameraPosition.BATTLE)
	if NET.server:
		NET.server.broadcast_start_game()


func go_to_map_editor():
	UI.ensure_camera_is_spawned()
	draw_mode = true
	UI.go_to_map_editor()


func _start_game_world():
	UI.go_to_main_menu()
	WM.start_world(game_setup_info.world_map)


func _start_game_battle():
	var map_data = game_setup_info.battle_map
	var armies : Array[Army]  = []

	for p in players:
		armies.append(create_army_for(p))

	UI.go_to_main_menu()
	BM.start_battle(armies, map_data, 0)


func create_army_for(player : Player) -> Army:
	var army = Army.new()
	army.controller = player
	army.units_data = player.slot.get_units_list()
	return army

#endregion


#region Gameplay UI


func go_to_main_menu():
	draw_mode = false
	BM.reset_grid_and_unit_forms()
	WM.close_world()
	UI.go_to_main_menu()


func toggle_in_game_menu():
	UI.toggle_in_game_menu()
	set_game_paused(UI.requests_pause())

#endregion


#region Technical
# not gameplay

func is_game_paused():
	return get_tree().paused


func set_game_paused(is_paused : bool):
	print("pause = ",is_paused)
	get_tree().paused = is_paused


func quit_game():
	get_tree().quit()

#endregion
