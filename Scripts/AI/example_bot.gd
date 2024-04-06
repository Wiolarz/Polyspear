class_name ExampleBot
"""
Bot with a state determined by tags
"""

extends AIInteface

enum TAG \
{
	IDLE,
	ATTACK,
	DEFEND,
}

var tagsSet: Dictionary = {} # [TAG -> null] used as Hash set

var current_state

func _ready():
	name = "ExampleBot"
	add_child(AiBotState.new([], me))
	add_child(AiBotStateDefensive.new([TAG.DEFEND], me))
	current_state = get_children()[0]

func add_tag(tag : TAG):
	if tagsSet.has(tag):
		return
	tagsSet[tag] = null
	# update state

func remove_tag(tag : TAG):
	if tagsSet.has(tag):
		tagsSet.erase(tag)
	# update state

func play_move() -> void: 
	var legal_moves = _get_possible_moves()
	var move = current_state.choose_move(legal_moves)
	BM.perform_ai_move( move, me )

func _get_possible_moves() -> Array[MoveInfo]:
	if BM.unsummoned_units_counter != 0:
		return AIHelpers.get_all_spawn_moves(me)
	
	var my_units : Array[AUnit] = BM.get_units(me)
	return AIHelpers.get_all_legal_moves(my_units, me)
