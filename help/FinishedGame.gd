extends Node

@onready var output_ui = $RichTextLabel

var scrolls = [4, 10, 20]

var fight_counter = 0
var monsters = [3, 7, 15]
var monster_names = ["goblin", "orc", "troll"]

var score = 0

func _ready():
	start_game()

func _process(delta):
	if are_fights_over():
		return
	
	var scrollNo = pick_scroll()
	if scrollNo > 0 and scrollNo <= scrolls.size():
		play_scroll(scrollNo)

# print with UI support
func output(text=""):
	print(text)
	output_ui.text += text + "\n"

func pick_scroll():
	var possible_inputs = {"KEY_1": 1, "KEY_2": 2, "KEY_3": 3,}
	var scrollNo = 0
	for key in possible_inputs.keys():
		if Input.is_action_just_pressed(key):
			scrollNo = possible_inputs[key]
	return scrollNo

func are_fights_over():
	return fight_counter == monsters.size()
	
func get_current_monster_name():
	return monster_names[fight_counter]

func get_current_monster_strength():
	return monsters[fight_counter]

func start_next_fight():
	fight_counter += 1

func start_game():
	output("Text game example")
	output("You will fight " + get_current_monster_name())
	output("")
	output("===============================================")
	output("Choose your scroll: " + str(scrolls))
	output("===============================================")

func play_scroll(scrollNo):
	var scrollStrenght = scrolls[scrollNo - 1];
	scrolls.remove_at(scrollNo - 1)
	output("You have chosen scroll # " + str(scrollNo) + " ("+str(scrollStrenght)+" str)")
	
	if player_won_combat(scrollStrenght):
		score += 1
	
	start_next_fight()

	if are_fights_over():
		output("")
		output("===============================================")
		output("End of the game! Your score: " + str(score))
		output("===============================================")
	else:
		output("")
		output("Next monster is: " + get_current_monster_name())
		output("===============================================")
		output("Choose your scroll: " + str(scrolls))
		output("===============================================")

func player_won_combat(scrollStrenght):
	var player = generate_creature(scrollStrenght)
	var enemy = generate_creature(get_current_monster_strength())
	output("Fight begins between Player's "+ str(player) + " and Enemy "+get_current_monster_name()+" " + str(enemy))

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

func generate_creature(value):
	var stats = [1, 1]
	for i in range(value):
		stats[randi_range(0, 1)] += 1
	return stats
