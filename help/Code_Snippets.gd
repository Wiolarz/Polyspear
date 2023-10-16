extends Node

class_name HELP

'''
static before func is needed only of an ease of use in project

'''


static func input_manager():
	# input
	var possible_inputs = {"KEY_1": 1, "KEY_2": 2, "KEY_3": 3,}
	
	var curent_choice = 0
	for key in possible_inputs.keys():
		if Input.is_action_just_pressed(key):
			curent_choice = possible_inputs[key]
	return curent_choice


static func creature_generator(value):
	var stats = [1, 1]
	for i in range(value):
		stats[randi_range(0, 1)] += 1
	return stats
