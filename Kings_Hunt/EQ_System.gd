extends Node

var resources = \
{
	"food": 0,
	"iron": 0,
	"gold": 0,
}

var levels = \
{
	"food": 1,
	"iron": 1,
	"gold": 1,
}
var requirements = \
{
	"gold" = 2,
	"iron" = 4,
	"food" = 5
}



func level_up(loot_name):
	var card_system = get_parent().get_node("Card_System")
	levels[loot_name] += 1
	if loot_name == "gold":
		var strongest_power = card_system.full_deck.max()
		card_system.full_deck.append(strongest_power + 4)
	elif loot_name == "iron":
		# buffing a weakest card
		# that is an above or equal to an average power of the full_deck
		var power_sum = 0
		for card in card_system.full_deck:
			power_sum += card
		var power_average = power_sum / card_system.full_deck.size()
		card_system.full_deck.sort()  # places the weakest card at the front
		for i in range(card_system.full_deck.size()):
			if card_system.full_deck[i] >= power_average:
				card_system.full_deck[i] += 4
	
	elif loot_name == "food":
		card_system.full_deck.sort()  # places the weakest card at the front
		card_system.full_deck.remove_at(0) # removes the weakest card

	
func award_resource(loot_name, quantity=1):
	resources[loot_name] += quantity
	while resources[loot_name] >= requirements[loot_name]:
		resources[loot_name] -= requirements[loot_name]
		level_up(loot_name)
			
	


