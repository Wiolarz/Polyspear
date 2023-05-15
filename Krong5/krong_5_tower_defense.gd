extends Node


@export var wave : Resource
@export var scrolls : Array[scroll] = [null, null, null]

func use_scroll(scrolls):
	var choice = randi_range(0, scrolls.size() - 1)
	var chosen_scroll = scrolls[choice]
	scrolls.remove_at(choice)
	return chosen_scroll

func scroll_force(scroll):
	var force = 0
	for attack in scroll.attacks:
		force += attack.bonus
		for i in range(attack.rolls):
			force += randi_range(1, attack.sides)
	return force
	

func _ready():
	#var scrolls = [20, 10, 5]
	
	for monster in wave.monsters:
		print(monster.name)
		var summon = use_scroll(scrolls)
		var force = scroll_force(summon)
		print("Scroll: ", summon.name, " ", force, " vs ", monster.power)
		if force > monster.power:
			print("you won")
		else:
			print("you lost")
		
		
		
	


func _process(delta):
	pass
