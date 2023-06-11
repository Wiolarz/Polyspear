extends Object

"""
Outpost but focused on a player controlled group of heroes

V1 - heroes have basic roll scores

"""
func _ready():
	var party = Party.new()
	for i in range(3):
		party.heroes.append(Hero.new())
	
	party.generate_dice_pool()
	print(party.scores)
	for i in range(10):
		var player_dice = party.use_dice()
		var enemy_dice = randi_range(1, 4)
		print(player_dice, " ", enemy_dice)
		print(score_check(enemy_dice - player_dice))
		print()


func score_check(modifier):  # enemy_dice - player_dice 
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
	
	func generate_scores():
		var scores = []
		for dice in dice_pool:
			scores.append(randi_range(1, dice))
		return scores


class Party:
	"""
	Hero Objects Manager
	"""
	var heroes = []
	var scores = []
	func generate_dice_pool():
		scores = []
		for hero in heroes:
			scores.append_array(hero.generate_scores())
	
	func use_dice():
		if scores.size() == 0:
			return 1
		var choice = randi_range(0, scores.size() - 1)
		var dice = scores[choice]
		scores.pop_at(choice)
		return dice
	
