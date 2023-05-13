extends Node

"""
Outpost but focused on a player controlled group of heroes

V2 - heroes have statistics that modify their chances on each test
"""

var ENEMY = {"type": null, "score": 0}
var STATE = "hero_choice"

var party = Party.new()

func _ready():
	print("START v2_Dice_Exploration")
	
	for i in range(3):
		party.heroes.append(Hero.new())
	
	
	
	
	party.generate_dice_pool()
	
	ENEMY["score"] = randi_range(1, 4)
	var types = ["STR", "AG"]
	types.shuffle()
	ENEMY["type"] = types[0]
	
	
	party.challenge(ENEMY["score"], ENEMY["type"])
	

		
		
	



func gameplay(input):
	if STATE == "hero_choice":
		party.choose_hero(input)
		STATE = "dice_choice"
		print()
		party.chosen_hero.dice_string(ENEMY["score"], ENEMY["type"])
		
	elif STATE == "dice_choice":
		var dice = party.chosen_hero.choose_dice(input)
		print("RESULT: ", score_check(ENEMY["score"] - dice))
		
		STATE = "hero_choice"
		ENEMY["score"] = randi_range(1, 4)
		var types = ["STR", "AG"]
		types.shuffle()
		ENEMY["type"] = types[0]
		print(ENEMY)
		
		party.challenge(ENEMY["score"], ENEMY["type"])






func score_check(modifier=0):  # enemy_dice - player_dice 
	""" Random event resolution mechanic
	
	Possible outcomes for each event are: Good / Neutral / Bad - GNB
	To determine outcome of an event we substract from Challenge level an Assigned score,
	to receive a value that determines a % chances for GNB ratio roll
	-4 - 100 | 0   | 0
	-3 - 80  | 20  | 0
	-2 - 60  | 35  | 10
	-1 - 40  | 40  | 20
	 0 - 25% | 50% | 25%
	+1 - 20  | 40  | 40
	+2 - 10  | 35  | 60
	+3 - 0   | 20  | 80
	+4 - 0   | 0   | 100"""
	modifier += 3
	if modifier < 0:
		return 1  # Positive outcome
	elif modifier > 6:
		return -1  # Bad outcome
	
	var gnb_values = [
		[80, 20, 0],   # -3
		[60, 35, 10],  # -2 
		[40, 40, 20],  # -1 # good outcome 
		[25, 50, 25],  # 0
		[20, 40, 40],  # +1 # bad outcome is more likely
		[10, 35, 60],  # +2
		[0, 20, 80]]   # +3
	
	
	var roll = randi_range(1, 100)
	if gnb_values[modifier][0] >= roll:
		return 1  # positive outcome
	elif gnb_values[modifier][1] + gnb_values[modifier][0] >= roll:
		return 0  # neutral outcome
	return -1 # negative outcome




class Hero:
	"""
	Basic player controlled asset
	"""
	var dice_pool = [6, 6]
	var attributes = {"STR": 1, "AG": -1}
	var scores_pool = []
	func generate_scores():
		scores_pool = []
		for dice in dice_pool:
			scores_pool.append(randi_range(1, dice))
		return scores_pool
	
	func scores_string(value, type):
		var result = ""
		for score in scores_pool:
			var mod_score = score + attributes[type]
			if mod_score >= value:
				result += "+" + str(score + attributes[type]) + " "
			else:
				result += "-" + str(score + attributes[type]) + " "
		return result
	
	func dice_string(value, type):
		for i in range(scores_pool.size()):
			var mod_score = scores_pool[i] + attributes[type]
			if mod_score >= value:
				print(i + 1, " +", scores_pool[i] + attributes[type])
			else:
				print(i + 1, " -", scores_pool[i] + attributes[type])
	
	func choose_dice(input):
		if input >= scores_pool.size():
			input = 0 
		var dice = scores_pool[input]
		scores_pool.remove_at(input)
		return dice
		
		

class Party:
	"""
	Hero Objects Manager
	
	When an event arises PLAYER sees all hero scores,
	with modifiers already applied and HERO stats shown beside
	Player can always choose an umodified 1, if he doesn't want to waste a dice
	
	
	"""
	var heroes = []
	var chosen_hero = null

	func generate_dice_pool():
		for hero in heroes:
			hero.generate_scores()
	
	
	func challenge(value, type):
		for hero_index in range(heroes.size()):
			print(hero_index + 1, " ", heroes[hero_index].scores_string(value, type))
			
	
	func choose_hero(input):
		if input < heroes.size():
			chosen_hero = heroes[input]
		else:
			print("wrong input")



func _process(delta):
	var inputs = ["KEY_1", "KEY_2", "KEY_3", "KEY_4"] # , "KEY_5", "KEY_6", "KEY_7", "KEY_8"
	for action_type in range(4):
		if Input.is_action_just_pressed(inputs[action_type]):
			gameplay(action_type)
			break
