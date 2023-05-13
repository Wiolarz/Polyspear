extends Node


"""
Test of limits what systemic game design may offer to text based games
Project focuses on managing a Fantasy Outpost.

Inspirations: Darkest Dungeon, 

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

Ideas:
	Allow player to assign dice scores for parrties during adventures
"""

""" PARTY
Hero Parties
Player's should be able progression wise to be capped at maximum 9 parties
There should always be at least single party with the player. (they could have a 0 cost being "Militia")
"""


""" ECONOMY
If player's gold drops below 0 he can still continue playing and getting deeper into deby,
he will just be unable to afford anything new.
It's an undisired state as the game aims to be easy
"""


""" ALIGNMENT
You as the ruler set the rules for the citizens to follow.
If those rules don't align with the king's orders he will reduce your income.
(He won't fire you as he trust you that those changes are only temporary)

Each rule may or may not allign with heroes party beliefs.
Which will then determine if the party will execute your law.
Even if the party doesn't agree with choice they still may have faith in you and follow anyway.
Level of their faith is the sum of all of their's matching beliefs.
Example:
	Militia group has the same alligment as the king, who requires for the nature to be purged
	Player deemed it neccesary to not anger local druids so he determined harming nature to be unlawful
	Militia encounter a rare deer, which body would be very valueable.
	But they decide not to kill it as their faith in the player's rule is strong enough as it was the only law that the player changed.
	
ALPHA VERSION:
	Each alignment category is currently in TRUE/FALSE only, as to make the game more simply, further down the line:
	Number of possible order may be lowered and more fluid, with outside factors being also taken into account:
		such as pay, additional rewards (items), pleasures at the town, workload


To stop conflict with faction some time has to pass for the war exhsaust to ammount

Permanent moral choices:
	killing townsfolk - BAD
	 

Example moral choices:
	Protect_Nature - 
	Legal_Theft - (robbing of means of survival = killing)
	Legal_Necromancy -
	Legal_Arcane Magic - 
	
	Imprisonment / Killing guilty -
	 
	
"""


""" FACTIONS
Represents a force on a continent, for example: Goblins.
When players damage a faction it gets weaker and appears less often. Factions regenarate over time.
Currently players are not capable of winning the game. (eliminating all enemy factions)


List of Factions:
	Druids:
		Nature - True, Necromancy - False
	
	Black order:
		Necromancy - True, Theft - False, Nature - False
	
	Lodge of Seers:
		Arcane - True, Theft - False, 
	
	Thieves Guild:
		Theft - True
	
	




Simplification in ALPHA version:
	Factions are not splitted between areas.
"""


func _ready():
	print("Start Project Outpost-Alpha")
	
	# world generation
	var list_of_all_regions = []
	var starting_regions = []  # list of regions known to player at the start
	
	var starting_party = Party.new()
	
	var player_town = Town.new()
	player_town.known_regions = starting_regions
	player_town.add_party(starting_party)


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
		To determine outcome of an event we subtract from Challenge level an Assigned score,
		to receive a value that determines a % chances for GNB ratio roll % dice
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
	var alignment
		
			
	
	func _init():

		# management data:
		assigned_schedule = {"day": null, "night": null}
		
		# Adventure data
		alignment = {"nature": true} # temporary setting to determine interactions between character,
		#sole basis will be proetection of the nature - true wants to protect
		#{"nature": 0, "murder": 0, "theft": 0} 
		
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
	
	
	func generate_power(power_level=1):
		""" Method for generting Party statistics based on their general power level
		"""
		cost = power_level
		
		var points = power_level * 10
		
		
	
	func create_score_pool():
		score_pool = []
		for dice in dice_pool:
			score_pool.append(randi_range(1, dice))
	
	func party_alignment_choice(problem: Dictionary):
		var order_choice = true
		
		for key in problem.keys():
			if alignment[key] == problem[key]:
				pass
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
