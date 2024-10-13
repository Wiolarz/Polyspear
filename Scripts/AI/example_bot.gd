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

@export var current_state : AiBotState


func _ready():
	add_child(AiBotStateRandom.new([], me))
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


func choose_move(battle_state : BattleGridState) -> MoveInfo:
	return current_state.choose_move(battle_state)
