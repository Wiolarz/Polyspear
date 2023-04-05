extends Node


# import Objects.*
# import Technical.*

# alpha 2.6 advanced location system introduction of polymorphism

var days # int global
var main_quest # global Quest object

'''
func overworld(company): # ArrayList<Hero>  # in java it was static, but variables here commented as global didn`t work
	
	var choice = 0 # int
	
	# days system
	days = 1
	company.add(Hero.create_mercenary(days))
	
	main_quest = Quest.new(days)
	
	var item_list = Economy.generate_items(days) # ArrayList<Item> 
	var world = Explore.generate_world() # ArrayList<Location> 
	
	
	while (choice != 9):
		if (main_quest.days_to_complete <= 0): # Time has run out DEFEAT
			Manager.exit(main_quest.fail_story, "quest_fail")


		match (choice):
			0: pass # starting value, also assigned in case of wrong input
			1, 2: pass# if choice was not to explore the days are not passing
			5, 6, 7: pass # debug days are not passing
			_: # 9 would be used to pass days	
				main_quest.days_to_complete -= 1
				main_quest.check_quest(company.get(0)) #
				days += 1
				company.add(Hero.create_mercenary(days))
				item_list = Economy.generate_items(days)


		#company.get(0).printing_all_stats()
		main_quest.print_info()
		# GAMEPLAY
		choice = Manager.choice("Day " + days + "  1 info   2 shop  3 world  9 Exit game")
		# END


		# list of locations
		match (choice):
			1: company.get(0).printing_all_stats() # info
			2: Economy.shop(company.get(0), item_list) # shop
			3:
				if(Explore.walking(company, world, days)):
					pass
				else:
					choice = 0 # player didn`t explore anything
					# TODO day system should be remade
			5:
				# try
				company.get(0).attack_speed -= 1
				company.get(0).generate_strategy()
				# catch (Exception e)
				# Manager.debug("unit cannot have 0 attack_speed")
				# company.get(0).attack_speed = 1
			6:
				company.get(0).attack_speed += 1
				company.get(0).generate_strategy()

			7: company.get(0).HP -= 1

			8: company.get(0).cheats() # :))



'''


# Called when the node enters the scene tree for the first time.
func _ready():
	print("Start of Console Dungeon")  # Manager.debug("Start")
	for i in range(0, 41):
		print(Manager.roman_numbers(i))
	# player creation
	#var player = Hero.new()

	var company = [] # ArrayList<Hero>
	#company.add(player)

	# start of the main gameplay loop
	#overworld(company)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
