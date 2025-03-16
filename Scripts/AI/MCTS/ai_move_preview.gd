class_name AIMovePreview
extends Node2D

const cross_marker_path = "res://Art/old/spear.png" # TODO change

var thread : AIThread

## MoveInfo => float
var move_scores_raw : Dictionary
var min_score := 0.0
var max_score := 1.0

## Vector2i => PositionMarker
var pos_markers: Dictionary
var markers : Array[Node2D]

@onready var reference_bot = load("res://Resources/Battle/Bots/MCTS_Hard.tscn")
@onready var arrow_marker = load("res://Scenes/UI/Battle/MoveMarkerArrow.tscn")


## Update battle grid state which is used in best move calculation
func update(bgs: BattleGridState):
	var mcts = BattleMCTSManager.new()
	var ref : AIBattleBotMCTS = reference_bot.instantiate()
	
	mcts.max_sim_iterations = ref.max_sim_turns
	mcts.heuristic_probability = ref.heuristic_probability
	mcts.heuristic_prior_reward_per_iteration = ref.heuristic_prior_reward_per_iteration
	mcts.max_playouts_per_visit = ref.max_playouts_per_visit
	mcts.debug_bmfast_internals = CFG.debug_check_bmfast_internals
	mcts.debug_max_saved_fail_replays = 4
	
	if thread:
		thread.destroy()
	thread = AIThread.from(bgs, mcts)
	thread.iteration_quant_finished.connect(_update_markers)
	thread.start()


func _update_markers():
	thread.lock()
	
	move_scores_raw = thread.move_scores#.mcts.get_move_scores()
	max_score = -10000.0
	min_score = 10000.0
	for i in move_scores_raw.values():
		max_score = max(max_score, i)
		min_score = min(min_score, i)
	
	for marker in markers:
		marker.queue_free()
	markers.clear()
	
	for cppmove in move_scores_raw.keys():
		var move = thread.bm.libspear_tuple_to_move_info(cppmove)
		_update_marker(cppmove, move)
	
	for pos in pos_markers:
		var marker_id = 0.0
		var no_markers = float(pos_markers[pos].size())
		
		# Create a circle of markers on a tile
		for marker_data : PositionMarker in pos_markers[pos]:
			var marker = Sprite2D.new()
			var offset = Vector2(0, -128).rotated(2*PI*marker_id/no_markers)
			
			marker.position = BM.to_position(pos) + offset
			marker.texture = load(marker_data.icon_path)
			# Make sure sprites are scaled properly regardless of their resolution
			marker.scale *= 196.0 / float(marker.texture.get_width())
			marker.modulate = get_modulate_for_score(marker_data.score)
			
			add_child(marker)
			markers.push_back(marker)
			marker_id += 1.0
	
	thread.unlock()
	thread.quant_processed_sem.post()
	pos_markers.clear()


func _update_marker(cppmove : Array, move : MoveInfo):
	var pos_marker = PositionMarker.new()
	pos_marker.score = move_scores_raw[cppmove]
	
	match move.move_type:
		MoveInfo.TYPE_MOVE:
			var marker: Node2D = arrow_marker.instantiate()
			
			var source = BM.to_position(move.move_source)
			var target = BM.to_position(move.target_tile_coord)
			
			marker.position = (source + target) / 2.0
			marker.look_at(target)
			marker.modulate = get_modulate_for_score(pos_marker.score)
			
			add_child(marker)
			markers.push_back(marker)
			
			pos_marker.score = -1.0
		MoveInfo.TYPE_SUMMON:
			pos_marker.icon_path = move.summon_unit.texture_path
		MoveInfo.TYPE_SACRIFICE:
			pos_marker.icon_path = cross_marker_path
		MoveInfo.TYPE_MAGIC:
			pos_marker.icon_path = move.spell.icon_path
		_:
			assert(false, "Unknown move type: %s" % [move.move_type])
	
	if pos_marker.score != -1.0:
		if move.target_tile_coord in pos_markers:
			pos_markers[move.target_tile_coord].push_back(pos_marker)
		else:
			pos_markers[move.target_tile_coord] = [pos_marker]


func get_modulate_for_score(score: float) -> Color:
	var result = Color.WHITE
	result.r = remap(score, min_score, max_score, 0.0, 1.0)
	result.g = remap(score, min_score, max_score, 0.0, 1.0)
	result.a = remap(score, min_score, max_score, 0.1, 1.0)
	return result


class PositionMarker:
	var icon_path: String
	var score: float
