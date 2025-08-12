class_name AIBattleBotMCTS
extends AIInterface

## Number of total playouts to be performed
@export var iterations := 100000
## How many turns before simulation terminates
@export var max_sim_turns := 80
## Probability of choosing a heuristically sensible move when choosing a random move
@export_range(0.0, 1.0) var heuristic_probability := 0.85
## Prior reward to encourage taking heuristically sensible moves,
## for example during the summoning phase
@export_range(0.0, 0.25) var heuristic_prior_reward_per_iteration := 0.01
## Number of max concurrent playouts per node visit/mcts iteration. [br]
## Higher value yields better performance on multicore systems
## at the possible expense of accuracy
@export var max_playouts_per_visit := 32
## When calculating a move with best reward per visit, add a pseudorandom
## noise to R/V so that suboptimal moves can be chosen [br]
## This is useful if the AI is too deterministic
@export_range(0.0, 1.0) var reward_per_visit_dither := 0.0

var _thread : AIThread

signal complete


func choose_move(state: BattleGridState) -> MoveInfo:
	
	var mcts = BattleMCTSManager.new()
	mcts.max_sim_iterations = max_sim_turns
	mcts.heuristic_probability = heuristic_probability
	mcts.heuristic_prior_reward_per_iteration = heuristic_prior_reward_per_iteration
	mcts.max_playouts_per_visit = max_playouts_per_visit
	mcts.debug_bmfast_internals = CFG.debug_check_bmfast_internals
	mcts.debug_max_saved_fail_replays = CFG.debug_mcts_max_saved_fail_replays
	
	_thread = AIThread.from(state, mcts, iterations)
	_thread.reward_per_visit_dither = reward_per_visit_dither
	add_child(_thread)
	_thread.start()
	
	await _thread.complete
	
	# Replaying failed playouts for debugging purposes
	# To debug, set a breakpoint in GDB on BattleManagerFast::play_moves
	var i = 0
	for moves in mcts.get_error_replays():
		push_error("Detected a failed MCTS playout no %s (move sequence: %s)" % [i, moves])
		var debugbm = BattleManagerFast.from(state)
		debugbm.set_debug_internals(true)
		debugbm.play_moves(moves)
		
		var replay: BattleReplay = BM._replay_data.duplicate()
		var bm_replay_helper = BattleManagerFast.from(state)
		for move in moves:
			replay.record_move(bm_replay_helper.libspear_tuple_to_move_info(move), 1000000)
			bm_replay_helper.play_move(move)
		replay.save_as("MCTS Fail %s" % [i])
		i += 1
	
	mcts.debug_print_move_lists = true
	var tuple = _thread.mcts.get_optimal_move(reward_per_visit_dither)
	var move = _thread.bm.libspear_tuple_to_move_info(tuple)
	
	# Just in case of bugs
	if move.target_tile_coord.x < 0 or move.target_tile_coord.y < 0:
		push_warning("Moves: %s" % [mcts.get_move_scores()])
		
		if CFG.debug_check_bmfast_integrity:
			assert(false, "MCTS AI tried to perform an invalid move")
		else:
			push_error("MCTS AI tried to perform an invalid move, falling back to random...")
		
		_thread.destroy()
		return AiBotStateRandom.choose_move_static(state)
	
	_thread.destroy()
	return move
