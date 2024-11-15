# Singleton - IM
# rename to GameManager
extends Node


## notifies when `game_setup_info` is modified
signal game_setup_info_changed

var game_setup_info : GameSetupInfo

var players : Array[Player] = []

## flag for MAP EDITOR
var in_map_editor : bool = false


func init_game_setup():
	game_setup_info = GameSetupInfo.create_empty()


#region Game setup

func get_world_maps_list() -> Array[String]:
	return FileSystemHelpers.list_files_in_folder(CFG.WORLD_MAPS_PATH)


func get_battle_maps_list() -> Array[String]:
	return FileSystemHelpers.list_files_in_folder(CFG.BATTLE_MAPS_PATH)


func _prepare_to_start_game() -> void:
	for player in players:
		player.queue_free()
	players = []
	for slot in game_setup_info.slots:
		var player := Player.create(slot)
		players.append(player)
		add_child(player)

	UI.ensure_camera_is_spawned()

	WM.close_world()
	BM.close_when_quiting_game()
	UI.go_to_main_menu()


## Starts a game in some state based on provided states and on game_setup_info.
## [br]
## If both states are null, then game is started as new and no state load is
## performed -- only game_setup_info is taken into account.
func start_game(world_state : SerializableWorldState, \
		battle_state : SerializableBattleState) -> void:

	assert(not battle_state or battle_state.valid())
	assert(not world_state or world_state.valid())

	_prepare_to_start_game()

	if game_setup_info.is_in_mode_battle():
		# in battle mode we can only have battle state
		assert(not world_state)

		_start_game_battle(battle_state)
		UI.set_camera(E.CameraPosition.BATTLE)

	elif game_setup_info.is_in_mode_world():
		# in world mode we can have no states, only world state or both states

		assert((not battle_state and not world_state) or
			(world_state))

		_start_game_world(world_state)
		UI.set_camera(E.CameraPosition.WORLD)
		if battle_state:
			var armies : Array[Army] = []
			for army_coord in battle_state.world_armies:
				armies.append(WM.world_state.get_army_at(army_coord))
			WM.start_combat(armies, battle_state.combat_coord, battle_state)

	if NET.server:
		NET.server.broadcast_start_game()


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
		slot.occupier = replay.get_player_name(slot_id)
		slot.set_units(units_array)

	start_game(null, null)
	BM.perform_replay(replay)


func go_to_map_editor():
	UI.ensure_camera_is_spawned()
	in_map_editor = true
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

	for player in players:
		armies.append(create_army_for(player))

	UI.go_to_main_menu()
	var x_offset = 0.0
	BM.start_battle(armies, map_data, battle_state, x_offset)


## Creates army based on player slot data
func create_army_for(player : Player) -> Army:
	var army = Army.new()
	army.controller_index = player.index

	var hero_data : DataHero = player.slot.slot_hero
	if hero_data:
		var new_hero = Hero.construct_hero(hero_data, player.index)
		army.hero = new_hero

	army.units_data = player.slot.get_units_list()

	#TEMP
	army.timer_reserve_sec = player.slot.timer_reserve_sec
	army.timer_increment_sec = player.slot.timer_increment_sec

	return army

#endregion Game setup


#region Gameplay UI

func go_to_main_menu():
	in_map_editor = false
	BM.close_when_quiting_game()
	WM.close_world()
	UI.go_to_main_menu()


func toggle_in_game_menu():
	UI.toggle_in_game_menu()
	set_game_paused(UI.requests_pause())

#endregion Gameplay UI


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


#endregion Technical


#region Information

func get_player_name(player : Player) -> String:
	if not player:
		return "neutral"
	var slot = player.slot
	if slot == null:
		return "neutral"
	return slot.get_occupier_name(game_setup_info.slots)


func get_player_color(player : Player) -> DataPlayerColor:
	if not player:
		return CFG.DEFAULT_TEAM_COLOR
	return player.get_player_color()

## 2 line string - Player color | controller name
func get_full_player_description(player : Player) -> String:
	return "%s\n%s" % [get_player_color(player).name, get_player_name(player)]


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
			for army in BM._battle_grid_state.armies_in_battle_state:
				state.world_armies.append(army.army_reference.coord)
			state.combat_coord = WM.combat_tile
	return state


func is_slot_steal_allowed() -> bool:
	if NET.server:
		return true # host always can steal slots
	elif NET.client:
		return NET.client.is_slot_steal_allowed()
	return true # local game

#endregion Information
