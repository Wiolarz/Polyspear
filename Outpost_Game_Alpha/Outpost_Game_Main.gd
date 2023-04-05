extends Node


"""
Game about managing a Fantasy outpost.

You manage groups of heroes by providing them equipment, services and choosing which area should they operate in.

Game operates in “turns” which are day and night cycles
Every odd turn  is a night.

Hero group can be assigned to a region as: 1 day 2 night 3 double shift 4 taking a break at an outpost.

Services operate between turns.

Medic - heals heroes for % of their missing health (keeping most heroes not fully healthy)
Smith - upgrades equipment depending on resources available
Seer/Tracker - provides information about regions
Scholar - provides experience points to heroes
Cook - provides temporary buffs (they don’t stack like smith’s)


"""

func _ready():
	print("Start Project Outpost-Alpha")



class Adventure:
	var item_stats = {
	"stone_sword": {"atk": 1},		
	}

	func _init(party, region):
		self.party = party
		self.party.create_score_pool()
		self.region = region
		
	
	func GNB_roll(score):
		"""Possible outcomes for each event are: Good / Neutral / Bad - GNB
		To determine outcome of an event we substract from Challenge level an Assigned score,
		to receive a value that determines a % chances for GNB ratio roll
		-4 100 0 0
		-3 80 20 0
		-2 60 35 10
		-1 40 40 20
		0 - 25% 50% 25%
		+1 20 40 40
		+2 10 35 60
		+3 0 20 80
		+4 0 0 100"""
		score += 3
		if score < 0:
			return 1  # Positive outcome
		elif score > 6:
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
		if gnb_values[score][0] >= roll:
			return 1  # positive outcome
		elif gnb_values[score][1] + gnb_values[score][0] >= roll:
			return 0  # neutral outcome
		return -1 # negative outcome
	
	




var game_state = "main"

var resources = {
	"stone": 0,
	"wood": 0,
	"bronze": 0,
	"iron": 0,
	"silver": 0,
	"gold": 0,
	"platinum": 0,
}


class Region:
	"""
	Region may a suprise a party of heroes with different events:
	
	Negative Event:
	
	A trap
	Natural blockade

	Positive event: Resource source (spot) (Collecting) /
	A rare game (sneak + spot) (hunt?) / Rare treasure (spot) (collecting, specific interaction)
	
	Neutral event: Neutral force contact / neutral village / neutral house
	Combat with large enemy / an enemy group / horde of enemies
	"""
	func _init():
		self.dice_pool = [6, 6, 6, 6]
		self.score_pool = []

class Faction:
	"""
	Represents a force on a continent, for example: Goblins.
	When players damage a faction it gets weaker and appears less often. Factions regenarate over time.
	Currently players are not capable of winning the game. (eliminating all enemy factions)
	"""
	""" Simplification in ALPHA version:
	Factions are not splitted between areas.
	"""
	func _init():
		#self.Enemies = [[1, 6], [2, 4], [3, 3], [4, 2], [5, 1]]
		self.power = 10


class Party:
	"""
	Party is a single entity object, representing different a group of heroes.
	"""
	func _init():
		self.dice_pool = [6, 6, 6, 6]
		self.score_pool = []
	
	func create_score_pool():
		self.score_pool = []
		for dice in self.dice_pool:
			self.score_pool.append(randi_range(1, dice))




func gameplay_state_controller(input):
	var output_text = str(input)
	pass



func _process(delta):

	var input_value = 0
	if Input.is_action_just_released("KEY_1"):
		input_value = 1
	elif Input.is_action_just_released("KEY_2"):
		input_value = 2
	elif Input.is_action_just_released("KEY_3"):
		input_value = 3
	
	if input_value != 0:
		gameplay_state_controller(input_value)
