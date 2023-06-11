extends Object


class_name heroes_draft



static func main_draft(input):
	print("Start Heroes_Draft")
	
	var inputs = ["1", "2", "3", "4", "5", "6", "7", "8"]
	var option = "1"
	
	option = int(option) - 1
	
	var heroes = ["a", "b", "c", "d", "e", "f", "g", "h"]
	var hero
	if len(heroes) > option:
		hero = heroes[option]
		heroes.remove_at(option)
	
	print(heroes)
	print(hero)


func test():
	print(11)
