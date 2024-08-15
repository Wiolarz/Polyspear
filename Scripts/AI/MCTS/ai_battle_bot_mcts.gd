class_name AIBattleBotMCTS extends AIInterface

@export var iterations = 100000

var thread: Thread

func choose_move(state: BattleGridState) -> MoveInfo:
	
	var unit_array = []
	var bm = BattleManagerFast.from(state, unit_array)
	
	var mcts = BattleMCTSManager.new()
	mcts.set_root(bm)
	mcts.max_sim_iterations = 80
	mcts.heuristic_probability = 0.85
	mcts.heuristic_prior_reward_per_iteration = 0.01
	mcts.max_playouts_per_visit = 32

	if thread:
		thread.wait_to_finish()
	thread = Thread.new()
	
	thread.start(
		mcts.iterate.bind(iterations), 
		Thread.PRIORITY_HIGH
	)
	await mcts.complete
	
	var unit = mcts.get_optimal_move_unit(0)
	var position = mcts.get_optimal_move_position(0)
	
	if unit_array[unit] is DataUnit: # Summon
		return MoveInfo.make_summon(unit_array[unit], position)
	else: # Move
		return MoveInfo.make_move(unit_array[unit].coord, position)
