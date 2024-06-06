# Singleton - BM
extends GridNode2D

var _battle_is_ongoing : bool = false

var _tile_grid : GenericHexGrid # Grid<TileForm>
var _battle_grid: BattleGridState

var _grid_tiles_node : Node2D
var _unit_forms_node : Node2D

var _battle_ui : BattleUI
var _anim_queue : Array[AnimInQueue] = []

var _current_summary : DataBattleSummary = null

var _selected_unit : Unit
var _unit_to_unit_form : Dictionary

var _replay_data : BattleReplay
var _replay_is_playing : bool = false


func _ready():
	_battle_ui = load("res://Scenes/UI/BattleUi.tscn").instantiate()

	_grid_tiles_node = Node2D.new()
	_grid_tiles_node.name = "GRID"
	add_child(_grid_tiles_node)

	_unit_forms_node = Node2D.new()
	_unit_forms_node.name = "UNITS"
	add_child(_unit_forms_node)

	UI.add_custom_screen(_battle_ui)


func _process(_delta):
	_process_anim_queue()


#region Battle Setup

func world_map_started():
	_battle_is_ongoing = false


func start_battle(new_armies : Array[Army], battle_map : DataBattleMap, \
		x_offset : float) -> void:

	assert(_is_clear(), "cannot start battle map, map already loaded")

	_replay_data = BattleReplay.create(new_armies, battle_map)
	_replay_data.save()

	UI.ensure_camera_is_spawned()
	UI.go_to_custom_ui(_battle_ui)

	_battle_is_ongoing = true

	_current_summary = null
	_selected_unit = null

	# GAMEPLAY GRID and Armies state:
	_battle_grid = BattleGridState.create(battle_map, new_armies)
	_battle_grid.on_unit_summoned.connect(_on_unit_summoned)
	_battle_grid.on_battle_ended.connect(_on_battle_ended)
	_battle_grid.on_turn_started.connect(_on_turn_started)

	# GRAPHICS GRID:
	_load_map(battle_map)
	_grid_tiles_node.position.x = x_offset

	_battle_ui.load_armies(_battle_grid.armies_in_battle_state)

	# first turn does not get a signal emit
	_on_turn_started(_battle_grid.get_current_player())


func _load_map(map : DataBattleMap) -> void:
	assert(_is_clear(), "cannot load map, map already loaded")
	_tile_grid = GenericHexGrid.new(map.grid_width, map.grid_height, null)
	_unit_to_unit_form.clear()
	for x in range(map.grid_width):
		for y in range(map.grid_height):
			var coord = Vector2i(x, y)
			var data = map.grid_data[x][y] as DataTile
			var tile_form = TileForm.create_battle_tile(data, coord)
			_tile_grid.set_hex(coord, tile_form)
			tile_form.position = to_position(coord)
			_grid_tiles_node.add_child(tile_form)


## space needed for battle tiles in global position
func get_bounds_global_position() -> Rect2:
	if _is_clear():
		push_warning("asking not initialized grid for camera bounding box")
		return Rect2(0, 0, 0, 0)
	var top_left_tile_position := get_tile_global_position(Vector2i(0,0))
	var bottom_right_tile_position  := \
			get_tile_global_position(Vector2i(_tile_grid.width-1, _tile_grid.height-1))
	var size : Vector2 = bottom_right_tile_position - top_left_tile_position
	return Rect2(top_left_tile_position, size)

#endregion


#region helpers

func can_show_battla_camera() -> bool:
	return _battle_is_ongoing


func should_block_world_interaction() -> bool:
	return _battle_is_ongoing


## converts from coordinates like 3,5 to actual position like 1200,300
func get_tile_global_position(coord : Vector2i) -> Vector2:
	return _tile_grid.get_hex(coord).global_position


## checks if map was cleaned properly, usually used for asserts
func _is_clear() -> bool:
	return _grid_tiles_node.get_child_count() == 0 \
			and _unit_forms_node.get_child_count() == 0 \
			and _tile_grid == null

#endregion


#region ongoing battle

func _on_turn_started(player : Player) -> void:
	if not _battle_is_ongoing:
		return

	_battle_ui.start_player_turn(_battle_grid.current_army_index)

	if player:
		# triggers AI analysis
		player.your_turn(_battle_grid)
	else:
		print("uncontrolled army's turn")


func perform_network_move(move_info : MoveInfo) -> void:
	_perform_move_info(move_info)


func perform_replay_move(move_info : MoveInfo) -> void:
	_perform_move_info(move_info)


func perform_ai_move(move_info : MoveInfo) -> void:
	_perform_move_info(move_info)


## called when tile is clicked
func grid_input(coord : Vector2i) -> void:
	if not _battle_is_ongoing:
		print("battle finished, input ignored")
		return

	if _replay_is_playing:
		print("replay playing, input ignored")
		return

	if _anim_queue.size() > 0:
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

#endregion


#region Summon Phase

## handles spawning unit form when unit is spawned on a gameplay map
## also connects animation related signals
func _on_unit_summoned(unit : Unit) -> void:
	var form := UnitForm.create(unit)
	_unit_forms_node.add_child(form)
	_unit_to_unit_form[unit] = form

	# apply correct BM position offset in world battles
	form.global_position = get_tile_global_position(unit.coord)

	_battle_ui.unit_summoned(not _battle_grid.is_during_summoning_phase(), unit.template)

	unit.unit_died.connect(_on_unit_killed.bind(unit))
	unit.unit_turned.connect(_on_unit_turned.bind(unit))
	unit.unit_moved.connect(_on_unit_moved.bind(unit))


## handles player input while during the summoning phase
func _grid_input_summon(coord : Vector2i) -> void:
	assert(_battle_grid.state == _battle_grid.STATE_SUMMONNING, \
			"_grid_input_summon called in an incorrect state")

	if _battle_ui.selected_unit == null:
		return # no unit selected to summon on ui

	if not _battle_grid.can_summon_on(_battle_grid.current_army_index, coord):
		return

	print(NET.get_role_name(), " input - summoning unit")
	var move_info = MoveInfo.make_summon(_battle_ui.selected_unit, coord)
	if NET.client:
		NET.client.queue_request_move(move_info)
		return # dont perform move, send it to server

	_perform_move_info(move_info)

#endregion


#region Fighting Phase

func _grid_input_fighting(coord : Vector2i) -> void:
	assert(_battle_grid.state == _battle_grid.STATE_FIGHTING, \
			"_grid_input_fighting called in an incorrect state")

	if try_select_unit(coord) or _selected_unit == null:
		# used in scenarios:
		# - selected a new unit
		# - clicked a tile with no ally units, when no unit was selected
		return

	# get_move_direction() returns MOVE_IS_INVALID on impossible moves, handles scenarios like
	# - spot is not adjacent (MOVE_IS_INVALID)
	# - spot is empty (dir)
	# - spot is not movable (MOVE_IS_INVALID)
	# - there is an enemy that can be killed by the move (dir)
	# - there is enemy that cannot be killed by the move (MOVE_IS_INVALID)
	var direction : int = _battle_grid.get_move_direction_if_valid(_selected_unit, coord)
	if direction == BattleGridState.MOVE_IS_INVALID:
		return

	_unit_to_unit_form[_selected_unit].set_selected(false)
	var move_info = MoveInfo.make_move(_selected_unit.coord, coord)
	_selected_unit = null

	if NET.client:
		NET.client.queue_request_move(move_info)
		return # dont perform move, send it to server

	_perform_move_info(move_info)


## Select friendly Unit on a given coord
## returns true if unit was selected
func try_select_unit(coord : Vector2i) -> bool:
	var new_unit : Unit = _battle_grid.get_unit(coord)
	if not new_unit:
		return false
	if new_unit.controller != _battle_grid.get_current_player():
		return false

	# deselect visually old unit if new one selected
	if _selected_unit:
		_unit_to_unit_form[_selected_unit].set_selected(false)

	_selected_unit = new_unit
	_unit_to_unit_form[_selected_unit].set_selected(true)
	return true


## used by input moves, replays, network and AI
func _perform_move_info(move_info : MoveInfo) -> void:
	if not _battle_is_ongoing:
		return
	print(NET.get_role_name(), " performing move ", move_info)
	_replay_data.record_move(move_info)
	_replay_data.save()
	if NET.server:
		NET.server.broadcast_move(move_info)
	if move_info.move_type == MoveInfo.TYPE_MOVE:
		_battle_grid.move_info_move_unit(move_info.move_source, move_info.target_tile_coord)
		return
	if move_info.move_type == MoveInfo.TYPE_SUMMON:
		_battle_grid.move_info_summon_unit(move_info.summon_unit, move_info.target_tile_coord)
		return
	assert(false, "Move move_type not supported in perform")


func _on_unit_killed(unit: Unit) -> void:
	_anim_queue.push_back(AnimInQueue.create_die(_unit_to_unit_form[unit]))
	_unit_to_unit_form.erase(unit)


func _on_unit_turned(unit: Unit) -> void:
	_anim_queue.push_back(AnimInQueue.create_turn(_unit_to_unit_form[unit]))


func _on_unit_moved(unit: Unit) -> void:
	_anim_queue.push_back(AnimInQueue.create_move(_unit_to_unit_form[unit]))


#endregion


#region Battle End

func close_when_quiting_game() -> void:
	_reset_grid_and_unit_forms()


## called when battle simulation decided battle was won
func _on_battle_ended() -> void:
	if not _battle_is_ongoing:
		assert(false, "battle ended when it was not ongoing...")
		return
	_battle_is_ongoing = false

	await get_tree().create_timer(1).timeout # TEMP, don't exit immediately
	while _replay_is_playing:
		await get_tree().create_timer(0.1).timeout

	_current_summary = _create_summary()
	_battle_ui.show_summary(_current_summary, _close_battle)


func _close_battle() -> void:
	var state_for_world = _battle_grid.armies_in_battle_state
	_turn_off_battle_ui()
	_reset_grid_and_unit_forms()

	if not WM.world_game_is_active():
		print("end of test battle")
		IM.go_to_main_menu()
		return

	WM.end_of_battle(state_for_world)


func _turn_off_battle_ui() -> void:
	_battle_ui.hide()
	UI.switch_camera()


func _reset_grid_and_unit_forms() -> void:
	_battle_is_ongoing = false
	_tile_grid = null
	_unit_to_unit_form.clear()
	Helpers.remove_all_children(_grid_tiles_node)
	Helpers.remove_all_children(_unit_forms_node)
	_battle_grid = null


func _create_summary() -> DataBattleSummary:
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

#endregion


#region Replays

func perform_replay(replay : BattleReplay) -> void:
	_replay_is_playing = true

	for m in replay.moves:
		if not _battle_is_ongoing:
			return # terminating battle while watching
		perform_replay_move(m)
		await _replay_move_delay()
	_replay_is_playing = false


func _replay_move_delay() -> void:
	await get_tree().create_timer(CFG.bot_speed_frames/60).timeout
	while IM.is_game_paused() or CFG.bot_speed_frames == CFG.BotSpeed.FREEZE:
		await get_tree().create_timer(0.1).timeout
		if not _battle_is_ongoing:
			return # terminating battle while watching

#endregion


#region cheats

func force_win_battle():
	_battle_grid.force_win_battle()


func force_surrender():
	_battle_grid.force_surrender()


#endregion


#region map editor

func load_editor_map(map : DataBattleMap) -> void:
	_load_map(map)


func unload_for_editor() -> void:
	_reset_grid_and_unit_forms()


func paint(coord : Vector2i, brush : DataTile) -> void:
	(_tile_grid.get_hex(coord) as TileForm).paint(brush)

#endregion


#region anim queue

func _process_anim_queue() -> void:
	if _anim_queue.size() == 0:
		return
	if not _anim_queue[0].started:
		_anim_queue[0].start()
	if _anim_queue[0].ended:
		_anim_queue.pop_front()
		return
	if not _anim_queue[0]._unit_form:
		var broken = _anim_queue.pop_front()
		push_warning("poping broken animation from the queue " + str(broken))


class AnimInQueue:
	var started : bool
	var ended : bool
	var debug_name : String
	var _unit_form : UnitForm
	var _animate : Callable


	static func create_turn(unit_form_ : UnitForm) -> AnimInQueue:
		var result = AnimInQueue.new()
		result.debug_name = "turn_"+unit_form_.unit.template.unit_name
		result._unit_form = unit_form_
		unit_form_.anim_end.connect(result.on_anim_end)
		result._animate = func () : unit_form_.start_turn_anim()
		return result


	static func create_move(unit_form_ : UnitForm) -> AnimInQueue:
		var result = AnimInQueue.new()
		result.debug_name = "move_"+unit_form_.unit.template.unit_name
		result._unit_form = unit_form_
		unit_form_.anim_end.connect(result.on_anim_end)
		result._animate = func () : unit_form_.start_move_anim()
		return result


	static func create_die(unit_form_ : UnitForm) -> AnimInQueue:
		var result = AnimInQueue.new()
		result.debug_name = "die_"+unit_form_.unit.template.unit_name
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


	func _to_string():
		return debug_name

#endregion
