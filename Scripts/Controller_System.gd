'''
sends an input system informations regarding card system state

then receives player choice and sends information toward card system and 
main node which will inform the game manager
'''

extends Node

class_name Controller_System

@export var action_buttons_container : HBoxContainer
@export var Cards_Container : VBoxContainer


@export var card_system : Card_System

@export var input : Node

var current_choice = "hide"

var player_controller = false

func _ready():
	if input.is_class("player_input"):
		player_controller = true
	
	input.connect("card", card_choice)
	input.connect("action", action_choice)


func card_choice(card_id):
	if player_controller:
		pass # attempt to highlight the card
	pass

func action_choice(action_name):
	pass

func turn_reset():
	current_choice = "hide"
