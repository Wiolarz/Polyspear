extends Node


@export var output : RichTextLabel


@onready var city = get_node("City")


func state_print():
	output.text = str(time / 60)
	
	output.text += "\n"
	
	
	
	# level related info - resources/activities
#	for key in location.keys():
#		output.text += "[" + key + "_" + str(location[key]) + "]"
	output.text += city.current_location
	output.text += "\n"
	
	# Level related info - enemies
	
	output.text += "Guards: "
	output.text += "\n"
	
	
	# player related info:
	
	# possedes resources, required resources
#	for key in player.resources.keys():
#		output.text += "[" + key + "-" + str(player.levels[key]) + ": " + \
#		str(player.resources[key]) + "/" + str(player.requirements[key]) + "]"
	
	# player attacks status
#	output.text += "HP: " + str(player.hp) + "  "
#	for i in range(player.cooldowns.size()):
#		output.text += "[" + str(player.attacks[i]) + ":" + str(player.cooldowns[i]) + "]"
#	output.text += "\n"
	
var time = 0


func _physics_process(delta):
	#if player.hp == 0:
	#	return
	time += 1
	
	var time_for_action = 180  # 3 seconds
	if Input.is_action_just_pressed("KEY_SPACE"):
		time = time_for_action
	
	
	# End of time for choice
	if time >= time_for_action: # and (time / 60) != 0
		time = 0
		# game logic
	
	state_print()
	
	
