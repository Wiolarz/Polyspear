extends Node
# export node arrays are bugged in godot 4.0

class_name player_input

signal card
signal action



func _physics_process(delta):
	"""
	
	"""
	
	var possible_action_inputs = \
	{"KEY_Q": "hide", "KEY_W": "run_up", "KEY_E": "run_down", "KEY_R": "search"}
	
	var possible_card_inputs = \
	["KEY_1", "KEY_2", "KEY_3", "KEY_4",] #  "KEY_5", "KEY_6", "KEY_7", "KEY_8",
		
	# input
	for key in possible_action_inputs.keys():
		if Input.is_action_just_pressed(key):
			emit_signal("action", possible_action_inputs[key])
	for i in range(possible_card_inputs.size()):
		if Input.is_action_just_pressed(possible_card_inputs[i]):
			emit_signal("action", i)

	

