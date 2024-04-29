class_name ExampleBot
extends AIInterface

"""
Bot with a state determined by tags
"""


enum TAG \
{
	IDLE,
	ATTACK,
	DEFEND,
}

var tags_set: Dictionary = {} # [TAG -> null] used as Hash set

var current_state


func _ready():
	name = "ExampleBot"
	add_child(AiBotStateRandom.new([], me))
	add_child(AiBotState.new([TAG.DEFEND], me)) # default state should crash the game
	current_state = get_children()[0]


func add_tag(tag : TAG):
	if tags_set.has(tag):
		return
	tags_set[tag] = null
	# update state


func remove_tag(tag : TAG):
	if tags_set.has(tag):
		tags_set.erase(tag)
	# update state


func play_move() -> void:
	var legal_moves = _get_possible_moves()
	assert(legal_moves.size() > 0, "play_move called with no moves to make")
	var move = current_state.choose_move(legal_moves)

	await ai_thinking_delay() # moving too fast feels weird
	BM.perform_ai_move( move, me )


func ai_thinking_delay() -> void:
	var seconds = CFG.bot_speed_frames / 60.0
	print("ai wait ", seconds)
	await get_tree().create_timer(seconds).timeout
	while IM.is_game_paused() or CFG.bot_speed_frames == CFG.BotSpeed.FREEZE:
		await get_tree().create_timer(0.1).timeout

func _get_possible_moves() -> Array[MoveInfo]:
	if BM.is_during_summoning_phase():
		return AIHelpers.get_all_spawn_moves(me)

	var my_units : Array[Unit] = BM.get_units(me)
	return AIHelpers.get_all_legal_moves(my_units, me)
