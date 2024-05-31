# Singleton - BM
extends GridNode2D

var grid_tiles_node : Node2D
var unit_forms_node : Node2D

var battle_is_ongoing : bool = false
var current_summary : DataBattleSummary = null

var battle_ui : BattleUI

var selected_unit : Unit
var unit_to_unit_form : Dictionary

var tile_grid : GenericHexGrid # Grid<TileForm>
var _battle_grid: BattleGridState

var _replay : BattleReplay
var _replay_is_playing : bool = false

var _waiting_for_action_to_finish : bool

var _anim_queue : Array[AnimInQueue] = []


func _ready():
	battle_ui = load("res://Scenes/UI/BattleUi.tscn").instantiate()

	grid_tiles_node = Node2D.new()
	grid_tiles_node.name = "GRID"
	add_child(grid_tiles_node)

	unit_forms_node = Node2D.new()
	unit_forms_node.name = "UNITS"
	add_child(unit_forms_node)

	UI.add_custom_screen(battle_ui)


func _process(_delta):
	if _anim_queue.size() == 0:
		return
	if not _anim_queue[0].started:
		_anim_queue[0].start()
	if _anim_queue[0].ended:
		_anim_queue.pop_front()


#region old B_GRID

func load_map(map : DataBattleMap) -> void:
	assert(is_clear(), "cannot load map, map already loaded")
	tile_grid = GenericHexGrid.new(map.grid_width, map.grid_height, null)
	unit_to_unit_form.clear()
	for x in range(map.grid_width):
		for y in range(map.grid_height):
			var coord = Vector2i(x, y)
			var data = map.grid_data[x][y] as DataTile
			var tile_form = TileForm.create_battle_tile(data, coord)
			tile_grid.set_hex(coord, tile_form)
			tile_form.position = to_position(coord)
			grid_tiles_node.add_child(tile_form)


func is_clear() -> bool:
	return grid_tiles_node.get_child_count() == 0 \
			and unit_forms_node.get_child_count() == 0 \
			and tile_grid == null


func reset_data():
	tile_grid = null
	unit_to_unit_form.clear()
	Helpers.remove_all_children(grid_tiles_node)
	Helpers.remove_all_children(unit_forms_node)


func get_tile(coord : Vector2i) -> TileForm:
	return tile_grid.get_hex(coord)


## for map editor only
func paint(coord : Vector2i, brush : DataTile) -> void:
	get_tile(coord).paint(brush)


func get_bounds_global_position() -> Rect2:
	if is_clear():
		push_warning("asking not initialized grid for camera bounding box")
		return Rect2(0, 0, 0, 0)
	var top_left_tile_form := get_tile(Vector2i(0,0))
	var bottom_right_tile_form := get_tile(Vector2i(tile_grid.width-1, tile_grid.height-1))
	var size : Vector2 = bottom_right_tile_form.global_position - top_left_tile_form.global_position
	return Rect2(top_left_tile_form.global_position, size)


#endregion

#region Battle Setup

func start_battle(new_armies : Array[Army], battle_map : DataBattleMap, \
		x_offset : float) -> void:
	_replay = BattleReplay.create(new_armies, battle_map)
	_replay.save()

	UI.ensure_camera_is_spawned()
	UI.go_to_custom_ui(battle_ui)

	battle_is_ongoing = true
	_waiting_for_action_to_finish = false

	current_summary = null
	# GAMEPLAY GRID:
	_battle_grid = BattleGridState.create(battle_map, new_armies)
	_battle_grid.on_unit_summoned.connect(on_unit_summoned)
	_battle_grid.on_battle_ended.connect(on_battle_ended)
	_battle_grid.on_turn_started.connect(on_turn_started)

	# GRAPHICS GRID:
	load_map(battle_map)
	grid_tiles_node.position.x = x_offset

	selected_unit = null
	battle_ui.load_armies(_battle_grid.armies_in_battle_state)

	on_turn_started(_battle_grid.get_current_player())

#endregion


#region Replay

func perform_replay(replay:BattleReplay) -> void:
	_replay_is_playing = true

	for m in replay.moves:
		if not battle_is_ongoing:
			return # terminating battle while watching
		perform_replay_move(m)
		await replay_move_delay()
	_replay_is_playing = false


func replay_move_delay() -> void:
	await get_tree().create_timer(CFG.bot_speed_frames/60).timeout
	while IM.is_game_paused() or CFG.bot_speed_frames == CFG.BotSpeed.FREEZE:
		await get_tree().create_timer(0.1).timeout
		if not battle_is_ongoing:
			return # terminating battle while watching

#endregion


#region Input Functions

## Currently only used for AI
func on_turn_started(player : Player) -> void:
	if not battle_is_ongoing:
		return

	battle_ui.start_player_turn(_battle_grid.current_army_index)

	if player:
		player.your_turn()
	else:
		print("uncontrolled army's turn")



## user clicked battle tile on given coordinates
func grid_input(coord : Vector2i) -> void:
	if _replay_is_playing:
		print("replay playing, input ignored")
		return

	if not battle_is_ongoing:
		print("battle finished, input ignored")
		return

	if _waiting_for_action_to_finish:
		print("anim playing, input ignored")
		return

	var current_player : Player =  _battle_grid.get_current_player()
	if current_player != null and current_player.bot_engine:
		print("ai playing, input ignored")
		return

	if _battle_grid.is_during_summoning_phase(): # Summon phase
		_grid_input_summon(coord)
		return

	_grid_input_fighting(coord)


func _grid_input_fighting(coord : Vector2i) -> void:

	if try_select_unit(coord) or selected_unit == null:
		# selected a new unit
		# or no unit selected and tile with no ally clicked
		return

	# get_move_direction() returns MOVE_IS_INVALID on impossible moves
	# detects if spot is empty or there is an enemy that can be killed by the move
	var direction : int = _battle_grid.get_move_direction_if_valid(selected_unit, coord)
	if direction == BattleGridState.MOVE_IS_INVALID:
		return

	unit_to_unit_form[selected_unit].set_selected(false)
	var move_info = MoveInfo.make_move(selected_unit.coord, coord)
	selected_unit = null

	if NET.client:
		NET.client.queue_request_move(move_info)
		return # dont perform move, send it to server

	perform_move_info(move_info)

## Select friendly Unit on a given coord
## returns true if unit was selected
func try_select_unit(coord : Vector2i) -> bool:
	var new_unit : Unit = _battle_grid.get_unit(coord)
	if not new_unit:
		return false
	if new_unit.controller != _battle_grid.get_current_player():
		return false

	# deselect visually old unit if selected
	if selected_unit:
		unit_to_unit_form[selected_unit].set_selected(false)

	selected_unit = new_unit
	unit_to_unit_form[selected_unit].set_selected(true)
	return true


func perform_network_move(move_info : MoveInfo) -> void:
	perform_move_info(move_info)


func perform_replay_move(move_info : MoveInfo) -> void:
	perform_move_info(move_info)


func perform_ai_move(move_info : MoveInfo) -> void:
	perform_move_info(move_info)


func perform_move_info(move_info : MoveInfo) -> void:
	if not battle_is_ongoing:
		return
	print(NET.get_role_name(), " performing move ", move_info)
	_replay.record_move(move_info)
	_replay.save()
	if NET.server:
		NET.server.broadcast_move(move_info)
	if move_info.move_type == MoveInfo.TYPE_MOVE:
		_battle_grid.move_info_move_unit(move_info.move_source, move_info.target_tile_coord)
		return
	if move_info.move_type == MoveInfo.TYPE_SUMMON:
		_battle_grid.move_info_summon_unit(move_info.summon_unit, move_info.target_tile_coord)
		return
	assert(false, "Move move_type not supported in perform")
#endregion



func turn_off_battle_ui() -> void:
	battle_ui.hide()
	UI.switch_camera()


func reset_grid_and_unit_forms() -> void:
	battle_is_ongoing = false
	reset_data()
	_battle_grid = null


func on_battle_ended() -> void:
	if not battle_is_ongoing:
		return
	battle_is_ongoing = false

	await get_tree().create_timer(1).timeout # TEMP, don't exit immediately
	while _replay_is_playing:
		await get_tree().create_timer(0.1).timeout

	current_summary = create_summary()
	battle_ui.show_summary(current_summary, close_battle)


func close_battle() -> void:
	turn_off_battle_ui()
	reset_grid_and_unit_forms()

	if not WM.world_game_is_active():
		print("end of test battle")
		IM.go_to_main_menu()
		return

	WM.end_of_battle(_battle_grid.armies_in_battle_state)

#endregion


#region Summon Phase

func on_unit_summoned(unit : Unit) -> void:
	var form := UnitForm.create(unit)
	unit_forms_node.add_child(form)
	form.global_position = get_tile(unit.coord).global_position

	battle_ui.unit_summoned(not _battle_grid.is_during_summoning_phase(), unit.template)

	unit_to_unit_form[unit] = form

	unit.unit_died.connect(on_unit_killed.bind(unit))
	unit.unit_turned.connect(on_unit_turned.bind(unit))
	unit.unit_moved.connect(on_unit_moved.bind(unit))

func on_unit_killed(unit: Unit) -> void:
	_anim_queue.push_back(AnimInQueue.create_die(unit_to_unit_form[unit]))
	unit_to_unit_form.erase(unit)

func on_unit_turned(unit: Unit) -> void:
	_anim_queue.push_back(AnimInQueue.create_turn(unit_to_unit_form[unit]))

func on_unit_moved(unit: Unit) -> void:
	_anim_queue.push_back(AnimInQueue.create_move(unit_to_unit_form[unit]))


func _grid_input_summon(coord : Vector2i) -> void:
	"""
	* Units are placed by the players in subsequent order on their chosen "Starting Locations"
	* inside the area of the gameplay board.
	"""
	if battle_ui.selected_unit == null:
		return # no unit selected

	if not _battle_grid.can_summon_on(_battle_grid.current_army_index, coord):
		return

	print(NET.get_role_name(), " input - summoning unit")
	var move_info = MoveInfo.make_summon(battle_ui.selected_unit, coord)
	if NET.client:
		NET.client.queue_request_move(move_info)
		return # dont perform move, send it to server
	perform_move_info(move_info)

#endregion


#region AI Helpers

func get_summon_tiles(player : Player) -> Array[Vector2i]:
	var idx = find_army_idx(player)
	return _battle_grid.get_summon_coords(idx)


func get_not_summoned_units(player : Player) -> Array[DataUnit]:
	for a in _battle_grid.armies_in_battle_state:
		if a.army_reference.controller == player:
			return a.units_to_summon.duplicate()
	assert(false, "ai asked for units to summon but it doesnt control any army")
	return []


func get_units(player : Player) -> Array[Unit]:
	var idx = find_army_idx(player)
	var armies_in_battle_state = _battle_grid.armies_in_battle_state
	return armies_in_battle_state[idx].units


func find_army_idx(player : Player) -> int:
	var armies_in_battle_state = _battle_grid.armies_in_battle_state
	for idx in range(armies_in_battle_state.size()):
		if armies_in_battle_state[idx].army_reference.controller == player:
			return idx
	assert(false, "ai asked for summon tiles but it doesnt control any army")
	return -1

#endregion


#region cheats

func force_win_battle():
	_battle_grid.force_win_battle()


func force_surrender():
	_battle_grid.force_surrender()


#endregion


#region Battle Summary


func get_summary() -> DataBattleSummary:
	if _battle_grid.state != BattleGridState.STATE_BATTLE_FINISHED:
		return null
	return current_summary


func create_summary() -> DataBattleSummary:
	var summary := DataBattleSummary.new()
	summary.color = CFG.NEUTRAL_COLOR.color
	summary.title = "Draw"

	var armies_in_battle_state := _battle_grid.armies_in_battle_state

	for army_in_battle in armies_in_battle_state:
		var player_stats := DataBattleSummaryPlayer.new()
		if army_in_battle.dead_units.size() <= 0:
			player_stats.losses = "< none >"
		else:
			for dead in army_in_battle.dead_units:
				var unit_description = "%s\n" % dead.unit_name
				player_stats.losses += unit_description

		var army_controller := army_in_battle.army_reference.controller
		player_stats.player_description = IM.get_full_player_description(army_controller)
		if army_in_battle.can_fight():
			player_stats.state = "winner"
			var color_description = CFG.NEUTRAL_COLOR
			if army_controller:
				color_description = army_controller.get_player_color()
			summary.color = color_description.color
			summary.title = "%s wins" % color_description.name
		else:
			player_stats.state = "loser"
		summary.players.append(player_stats)
	return summary


#end region

class AnimInQueue:
	var started : bool
	var ended : bool
	var _unit_form : UnitForm
	var _animate : Callable

	static func create_turn(unit_form_ : UnitForm) -> AnimInQueue:
		var result = AnimInQueue.new()
		result._unit_form = unit_form_
		unit_form_.anim_end.connect(result.on_anim_end)
		result._animate = func () : unit_form_.start_turn_anim()
		return result

	static func create_move(unit_form_ : UnitForm) -> AnimInQueue:
		var result = AnimInQueue.new()
		result._unit_form = unit_form_
		unit_form_.anim_end.connect(result.on_anim_end)
		result._animate = func () : unit_form_.start_move_anim()
		return result

	static func create_die(unit_form_ : UnitForm) -> AnimInQueue:
		var result = AnimInQueue.new()
		result._unit_form = unit_form_
		unit_form_.anim_end.connect(result.on_anim_end)
		result._animate = func () : unit_form_.start_death_anim()
		return result

	func start() -> void:
		started = true
		_animate.call()


	func on_anim_end() -> void:
		ended = true
		_unit_form.anim_end.disconnect(on_anim_end)

