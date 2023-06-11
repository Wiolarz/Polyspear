extends Node


@export var output : RichTextLabel

# TODO research if ONREADY here is neccesary
var scene = load("res://Krong8/player_character.tscn")  


func _ready() -> void:
	print("Start of the Krong 7")
	test()
	

func test():
	""" try to create fresh player character and enemy character
	deal damage ot one of them randomly and then if someone dies 
	a new character is spawned
	"""
	
	var instance = scene.instantiate()
	add_child(instance)
	






func generate_room(lvl=1):
	var room = {"gold": randi_range(0, 3),
	"iron": randi_range(0, 3),
	"food": randi_range(0, 3)}
	for key in room.keys():
		if room[key] == 0:
			room.erase(key)
	
	return room



func generate_attack():
	if randi_range(1, 4) != 1:
		next_attack = null
		return
	
	next_attack = randi_range(1, 40)
	next_attack_suggestion = clamp(next_attack + randi_range(-5, 5), 1, 40)
	

'''
func state_print():
	output.text = str(time / 60) + "    current choice: " + current_choice
	if current_choice in ["combat_1", "combat_2", "combat_3"]:
		output.text += " " + player.attack_info(current_choice)
	output.text += "\n"
	
	output.text += "next attack: "
	if next_attack == null:
		output.text += "___"
	else:
		output.text += str(next_attack_suggestion)
	output.text += "\n"
	
	# level resources
	for key in location.keys():
		output.text += "[" + key + "_" + str(location[key]) + "]"
	output.text += "\n"
	
	# possedes resources, required resources
	for key in player.resources.keys():
		output.text += "[" + key + "-" + str(player.levels[key]) + ": " + \
		str(player.resources[key]) + "/" + str(player.requirements[key]) + "]"
	
	# player attacks status
	output.text += "HP: " + str(player.hp) + "  "
	for i in range(player.cooldowns.size()):
		output.text += "[" + str(player.attacks[i]) + ":" + str(player.cooldowns[i]) + "]"
	output.text += "\n"
	
	# update attack buttons
	var text_attack_buttons = "combat"
	for i in range(player.attacks.size()):
		attack_buttons[i].text = text_attack_buttons + str(i + 1) + " "  \
			+ str(player.attacks[i])
'''

var time = 0
var level = 1


var next_attack = null
var next_attack_suggestion = 1
var location = generate_room()

# var player = Player.new() TODO
var current_choice = "mine"

func _physics_process(delta):
	#if player.hp == 0:
	#	return
	time += 1
	
	var time_for_action = 180  # 3 seconds
	if Input.is_action_just_pressed("KEY_SPACE"):
		time = time_for_action
		
	# adding rest of the information
	if time >= time_for_action and (time / 60) != 0:
		pass
	
	#state_print()
	
	
