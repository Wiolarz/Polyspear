class_name AIBattleBotMCTS extends AIInterface

## Number of total playouts to be performed
@export var iterations = 100000
## How many turns before simulation terminates
@export var max_sim_turns: int = 80
## Probability of choosing a heuristically sensible move when choosing a random move
@export var heuristic_probability: float = 0.85
## Prior reward to encourage taking heuristically sensible moves, [br]
## for example during the summoning phase
@export var heuristic_prior_reward_per_iteration: float = 0.01
## Number of max concurrent playouts per node visit/mcts iteration. [br]
## Higher value yields better performance on multicore systems [br]
## at the possible expense of accuracy
@export var max_playouts_per_visit: int = 32

var iterate_complete_mutex := Mutex.new()
var is_iterate_complete: bool = false
var thread: Thread

signal complete


func choose_move(state: BattleGridState) -> MoveInfo:
	var bm = BattleManagerFast.from(state)
	
	var mcts = BattleMCTSManager.new()

	mcts.set_root(bm)
	mcts.max_sim_iterations = max_sim_turns
	mcts.heuristic_probability = heuristic_probability
	mcts.heuristic_prior_reward_per_iteration = heuristic_prior_reward_per_iteration
	mcts.max_playouts_per_visit = max_playouts_per_visit
	
	# Roundabout way to ensure the signal is handled by the main thread
	mcts.complete.connect(func():
		iterate_complete_mutex.lock() 
		set_deferred("is_iterate_complete", true)
		iterate_complete_mutex.unlock()
	)
	
	thread = Thread.new()
	
	thread.start(
		mcts.iterate.bind(iterations), 
		Thread.PRIORITY_HIGH
	)
	await complete
	
	var tuple = mcts.get_optimal_move(0)
	return bm.libspear_tuple_to_move_info(tuple)

func cleanup_after_move():
	if thread:
		thread.wait_to_finish()
	thread = null

func _process(_delta):
	# Suddenly awaiting on timer from a worker thread became an issue for some reason
	iterate_complete_mutex.lock()
	if is_iterate_complete:
		is_iterate_complete = false
		complete.emit()
	iterate_complete_mutex.unlock()
