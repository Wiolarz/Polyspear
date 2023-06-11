extends Node

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


'''
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
			
	




'''
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
