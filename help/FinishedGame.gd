extends Node

@onready var output_window = $RichTextLabel


var fight_counter = 0
var scrolls = [4, 10, 20]
var monsters = [3, 7, 15]
var monster_names = ["goblin", "orc", "troll"]

var score = 0

func output(text=""):
	# print replacement
	print(text)
	output_window.text += text + "\n"



func creature_generator(value):
	var stats = [1, 1]
	for i in range(value):
		stats[randi_range(0, 1)] += 1
	return stats



func _ready():
	output("Text game example")
	gameplay(0)

		
func combat(player, enemy):
	output("Fight begins between Player's"+ str(player) + " and Enemy " + str(enemy))
	var round_counter = 0
	while player[1] > 0 and enemy[1] > 0:
		round_counter += 1
		output("round " + str(round_counter))
		player[1] -= enemy[0]
		enemy[1] -= player[0]
		output("Player-"+ str(player) + " || Enemy-" + str(enemy))
	
	var result = enemy[1] <= 0
	if result:
		output("player win")
	else:
		output("moster win")
	
	return result
	
	


func gameplay(player_input):
	if player_input == 0:
		# introduction
		output("You will fight " + monster_names[fight_counter])
		output("Choose your scroll: " + str(scrolls))
		return
	output("You have chosen " + str(player_input) + " scroll")
	var player = creature_generator(scrolls[player_input - 1])
	var enemy = creature_generator(monsters[fight_counter])
	
	if combat(player, enemy):
		output()
		score += 1
	
	fight_counter += 1
	if fight_counter == monsters.size():
		output("End of the game! Your score:" + str(score))
		return
	
	output("Next monster is: " + monster_names[fight_counter])
	


func _process(delta):
	if fight_counter == monsters.size():
		return
	
	# input
	var possible_inputs = {"KEY_1": 1, "KEY_2": 2, "KEY_3": 3,}
	
	var curent_choice = 0
	for key in possible_inputs.keys():
		if Input.is_action_just_pressed(key):
			curent_choice = possible_inputs[key]
	
	
	if curent_choice != 0 and curent_choice <= scrolls.size():
		gameplay(curent_choice)
		
		
		
		
