extends Node

class_name StateMachine

var states : Dictionary = {} # there should always be at least a single state

var current_state



func _ready():
	var children = get_children()

	for child in children:
		
		if child.StartingState:
			current_state = child


		for tag in child.tags:
			if tag in states.keys():
				states[tag].append(child)
			else:
				states[tag] = [child]



func change_state(new_states):
	var new_chosen_state
	for new_state in new_states:

		if new_state in states.keys():
			new_chosen_state = new_state
			break
		
	if new_chosen_state == null:
		for state in states.keys():
			if state not in current_state.tags:
				new_chosen_state = state
				break
		new_chosen_state = states.keys()[0]
	

	# we have chosen the tag name for our new state, write the transisiton
	
	pass



