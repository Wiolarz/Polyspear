extends Node

"""
Game about managing your knight equipment

knight has statistics that increase over time. He brings you stuff with which you can create EQ

Statistics requirements for items works drain attributes pool example:
Knight with 5 STR can wear sword 4 STR and Armor 1 STR
if he had chosen a sword with 3 STR he could additionally take a 1 STR shield

"""


func _ready():
	print("Start Project 3")




var game_state = "main"


class Knight:
	func _init():
		pass
	




func gameplay_state_controller(input):
	pass



func _process(delta):

	var input_value = 0
	if Input.is_action_just_released("KEY_1"):
		print("1")
		input_value = 1
	elif Input.is_action_just_released("KEY_2"):
		print("2")
		input_value = 2
	elif Input.is_action_just_released("KEY_3"):
		print("3")
		input_value = 3
	
	if input_value != 0:
		gameplay_state_controller(input_value)
	
