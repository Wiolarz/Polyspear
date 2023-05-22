extends Node

@export var output : Node


func _ready() -> void:
	print("Start of the Krong 6")


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
	


class Player:
	var hp = 3
	var mine_power = 4
	var cooldown_reset = 10
	var resources = \
	{
		"gold": 0,
		"iron": 0,
		"food": 0
	}
	
	var levels = \
	{
		"gold" = 1,
		"iron" = 1,
		"food" = 1
	}
	var requirements = \
	{
		"gold" = 2,
		"iron" = 4,
		"food" = 5
	}
	
	var attacks = [20, 5, 10]
	var cooldowns = [0, 0, 0]
	
	func attack_info(current_choice):
		var choice = {"combat_1": 0,
		"combat_2": 1,
		"combat_3": 2}
		if cooldowns[choice[current_choice]] == 0:
			return str(attacks[choice[current_choice]])
		else:
			return "cooldown[" + str(cooldowns[choice[current_choice]]) + "]"
	
	
	func level_up(loot_name):
		levels[loot_name] += 1
		if loot_name == "gold":
			attacks[randi_range(0, 2)] += 3
		elif loot_name == "iron":
			mine_power += 1
		elif loot_name == "food":
			cooldown_reset = clamp(cooldown_reset - 1, 0, cooldown_reset)
		
			
			
	
	func award_resource(loot_name, quantity=1):
		resources[loot_name] += quantity
		while resources[loot_name] >= requirements[loot_name]:
			resources[loot_name] -= requirements[loot_name]
			level_up(loot_name)
			
	


var time = 0
var current_choice = "mine"

var level = 1
var next_attack = null
var next_attack_suggestion = 1
var location = generate_room()

var player = Player.new()

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


func _physics_process(delta):
	if player.hp == 0:
		return
	time += 1
	state_print()
	
	var possible_inputs = {"KEY_Q": "mine", "KEY_W": "run", "KEY_1": "combat_1", "KEY_2": "combat_2", "KEY_3": "combat_3", }
	# input
	for key in possible_inputs.keys():
		if Input.is_action_just_pressed(key):
			current_choice = possible_inputs[key]
			
			
	var time_for_action = 180  # 3 seconds
	if Input.is_action_just_pressed("KEY_SPACE"):
		time = time_for_action
		
	# adding rest of the information
	if time >= time_for_action and (time / 60) != 0:
		
		if current_choice == "run":
			level += 1
			location = generate_room()
		elif next_attack != null:  # Fight
			var combat_power = 0
			var combat_choice = ["combat_1", "combat_2", "combat_3"]
			if current_choice in combat_choice:
				combat_choice = combat_choice.find(current_choice)
				if player.cooldowns[combat_choice] == 0:
					player.cooldowns[combat_choice] = player.cooldown_reset
					combat_power = player.attacks[combat_choice]
			if combat_power < next_attack:
				player.hp -= 1
				if player.hp == 0:
					output.text = "game over"
					return
		else:  # mine
			for i in range(player.mine_power):
				
				var choice = location.keys()
				if choice.size() == 0:
					break
				choice.shuffle()
				choice = choice[0]
				player.award_resource(choice)
				location[choice] -= 1
				if location[choice] == 0:
					location.erase(choice)
			
		
		# reset turn
		current_choice = "mine"
		for i in range(player.cooldowns.size()):
			if player.cooldowns[i] > 0:
				player.cooldowns[i] -= 1
		time = 0
		generate_attack()
		state_print()
		# new info
		
		
