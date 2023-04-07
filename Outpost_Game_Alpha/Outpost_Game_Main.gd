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
""" General design vision:
Game should be easy - progression should be never slowed down below enjoyable levels

"""

""" Hero Parties: "Party"
Player's should be able progression wise be able to attain more than 9 parties
There should always be at least single party with the player. (they could have a 0 cost being "Militia")
"""


""" ECONOMY
If player's gold drops below 0 he can still continue playing and getting deeper into deby,
he will just be unable to afford anything new.
It's an undisired state as the game aims to be easy
"""




func _ready():
	print("Start Project Outpost-Alpha")
	
	# world generation
	var list_of_all_regions = []
	var starting_regions = []  # list of regions known to player at the start
	
	var starting_party = Party.new()
	starting_party.test()
	'''
	
	var player_town = Town.new()
	player_town.known_region = starting_regions
	player_town.add_party(starting_party)'''


class Adventure:
	var item_stats = {
	"stone_sword": {"atk": 1},		
	}
	var party
	var region
	func _init(party, region):
		party = party
		party.create_score_pool()
		region = region
		
	
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
	var name
	func _init():
		name = "test"
	
	func info():
		return name

class Faction:
	"""
	Represents a force on a continent, for example: Goblins.
	When players damage a faction it gets weaker and appears less often. Factions regenarate over time.
	Currently players are not capable of winning the game. (eliminating all enemy factions)
	"""
	""" Simplification in ALPHA version:
	Factions are not splitted between areas.
	"""
	var enemies
	var power
	func _init():
		#enemies = [[1, 6], [2, 4], [3, 3], [4, 2], [5, 1]]
		power = 10


class Party:
	"""
	Party is a single entity object, representing different a group of heroes.
	"""
	var assigned_schedule
	var dice_pool
	var score_pool
	var cost
	var overpayment
	func _init():

		# management data:
		assigned_schedule = {"day": null, "night": null}
		
		# Adventure data
		dice_pool = [6, 6, 6, 6]
		score_pool = []
		var item_list: int:
			get:
				return item_list
			set(value):
				print("test")
				item_list = value
		
		# Economy:
		cost = 1
		overpayment = 0
	
	func create_score_pool():
		score_pool = []
		for dice in dice_pool:
			score_pool.append(randi_range(1, dice))
	
	func test():
		print(assigned_schedule)
	
	
	func schedule_info():
		if assigned_schedule["day"] == null:
			if assigned_schedule["night"] == null:
				return "not-assigned"
			else:
				return "N: " + assigned_schedule["night"].info()
		elif assigned_schedule["night"] == null:
			return "D: " + assigned_schedule["day"].info()
		return "D: " + assigned_schedule["day"].info() + " N: " + assigned_schedule["night"].info()


class Item:
	"""
	Item is a simple object that can be either sold for gold or
	given to a party which will boost them while also
	satysfaing party gold demand for the 50% of the item's value
	"""
	var dice_pool
	var score_pool
	var gold
	var income
	var expenses
	var cycles_count
	func _init():
		dice_pool = [6, 6, 6, 6]
		score_pool = []
		
		gold = 10
		income = 3
		expenses = 0
		
		cycles_count = 0


class Town:
	"""
	Town is a player entity that handles all players resources and actions
	"""
	var party_groups
	var known_regions
	var gold
	var income
	var expenses
	var cycles_count
	func _init():
		"""Start of the game"""
		
		# management resourcers
		party_groups = []
		known_regions = []
		
		
		# Economy
		gold = 10
		income = 3
		expenses = {"next_day": 0, "overall": 0, "savings": 0}
		'''next day represents what player will have to pay
		overall what the player has to pay regardless of overpayment
		savings shows accumulated overpayment in parties pockets'''
		
		
		
		
		
	func new_cycle():
		"""Start of a new cycle either a day or a night"""
		cycles_count += 1
		var pay
		if cycles_count % 2 == 0:  # new day
			gold += income
			for party in party_groups:
				pay = clamp(party.cost - party.overpayment, 0, party.cost)
				party.overpayment -= pay
				gold -= pay
		
	
	func check_expenses():
		expenses = {"next_day": 0, "overall": 0, "savings": 0}  # reset values
		for party in party_groups:
			expenses["overall"] += party.cost
			expenses["savings"] += party.overpayment
			expenses["next_day"] += clamp(party.cost - party.overpayment, 0, party.cost)
			
	
	
	
	
			
	func add_party(party):  # still not sure how import having a setter here is?
		party_groups.append(party)


	
func gameplay_state_controller(input):
	var output_text = str(input) + " "
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
