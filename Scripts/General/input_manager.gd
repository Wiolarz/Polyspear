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


func _prepare_to_start_game() -> void:
	for p in players:
		p.queue_free()
	players = []
	for s in game_setup_info.slots:
		var p := Player.create(s)
		players.append(p)
		add_child(p)

	UI.ensure_camera_is_spawned()

	WM.close_world()
	BM.close_when_quiting_game()
	UI.go_to_main_menu()


## starts a new game based on game_setup_info
func start_new_game() -> void:

	_prepare_to_start_game()

	if game_setup_info.is_in_mode_world():
		_start_game_world(null)
		UI.set_camera(E.CameraPosition.WORLD)
	if game_setup_info.is_in_mode_battle():
		_start_game_battle(null)
		UI.set_camera(E.CameraPosition.BATTLE)
	if NET.server:
		NET.server.broadcast_start_game()


## starts a game in some state based on provided states and on game_setup_info
func start_game_in_state(world_state : SerializableWorldState, \
		battle_state : SerializableBattleState) -> void:

	_prepare_to_start_game()

	if game_setup_info.is_in_mode_battle() and battle_state.valid():
		_start_game_battle(battle_state)
		UI.set_camera(E.CameraPosition.BATTLE)
		UI.go_to_custom_ui(BM._battle_ui)
	elif game_setup_info.is_in_mode_world() and world_state.valid():
		_start_game_world(world_state)
		UI.set_camera(E.CameraPosition.WORLD)
		UI.go_to_custom_ui(WM.world_ui)
		if battle_state.valid():
			var armies : Array[Army] = []
			for army_coord in battle_state.world_armies:
				armies.append(WM.world_state.get_army_at(army_coord))
			WM.start_combat(armies, battle_state.combat_coord, battle_state)
			UI.go_to_custom_ui(BM._battle_ui)


func perform_replay(path):
	var replay = load(path) as BattleReplay
	assert(replay != null)

	game_setup_info.game_mode = GameSetupInfo.GameMode.BATTLE
	game_setup_info.battle_map = replay.battle_map

	assert(game_setup_info.slots.size() == replay.units_at_start.size(), \
			"for now only 1v1 implemented")
	for slot_id in range(replay.units_at_start.size()):
		var slot = game_setup_info.slots[slot_id]
		var units_array = replay.units_at_start[slot_id]
		slot.occupier = ""
		slot.set_units(units_array)

	start_new_game()
	BM.perform_replay(replay)


func go_to_map_editor():
	UI.ensure_camera_is_spawned()
	draw_mode = true
	UI.go_to_map_editor()


## new game <=> world_state == null
func _start_game_world(world_state : SerializableWorldState):
	UI.go_to_main_menu()
	var map : DataWorldMap = game_setup_info.world_map
	if not world_state:
		WM.start_new_world(map)
	else:
		WM.start_world_in_state(map, world_state)

## new game <=> battle_state == null
func _start_game_battle(battle_state : SerializableBattleState):
	var map_data = game_setup_info.battle_map
	var armies : Array[Army]  = []

	for p in players:
		armies.append(create_army_for(p))

	UI.go_to_main_menu()
	var x_offset = 0.0
	BM.start_battle(armies, map_data, battle_state, x_offset)


func create_army_for(player : Player) -> Army:
	var army = Army.new()
	army.controller = player
	army.units_data = player.slot.get_units_list()
	return army

#endregion


#region Gameplay UI


func go_to_main_menu():
	draw_mode = false
	BM.close_when_quiting_game()
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


func get_player_by_index(index : int) -> Player:
	if index in range(players.size()):
		return players[index]
	return null


func get_index_of_player(player : Player) -> int:
	for i in range(players.size()):
		if players[i] == player:
			return i
	return -1


#endregion


#region Information


func get_full_player_description(player : Player) -> String:
	if not player:
		return "neutral"
	var slot = player.slot
	if slot == null:
		return "neutral"
	var the_name : String = "somebody"
	if slot.is_bot():
		var number_of_ais : int = 0
		var index_of_this_ai : int = 0
		for counted_slot in game_setup_info.slots:
			if counted_slot.is_bot():
				if counted_slot == slot:
					index_of_this_ai = number_of_ais
				number_of_ais += 1
		if number_of_ais > 1:
			the_name = "AI %s" % index_of_this_ai
		else:
			the_name = "AI"
	elif slot.occupier == "":
		the_name = NET.get_current_login()
	else:
		the_name = slot.occupier as String
	var color = player.get_player_color()
	return "%s\n%s" % [color.name, the_name]


func get_serializable_world_state() -> SerializableWorldState:
	var state := SerializableWorldState.new()
	if WM.world_game_is_active():
		state = WM.get_serializable_state()
	return state


func get_serializable_battle_state() -> SerializableBattleState:
	var state := SerializableBattleState.new()
	if BM.battle_is_active():
		state.replay = BM.get_ripped_replay()
		if WM.world_game_is_active():
			for army in BM._battle_grid.armies_in_battle_state:
				state.world_armies.append(army.army_reference.coord)
			state.combat_coord = WM.combat_tile
	return state


#endregion
