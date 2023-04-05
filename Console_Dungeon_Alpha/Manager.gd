extends Object

class_name Manager

# Called when the node enters the scene tree for the first time.
func _ready() :
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
static func debug(txt):  # String
	print(txt)


static func error(txt): # String
	print(txt)


# TODO TEST ROMAN NUMBERS
static func roman_numbers(value): # returns String, takes int
	# Conversion of int into a roman number (works correctly to a max number of 39)
	var result = ""
	
	while (value > 10):
		result += "X"
		value -= 10

	match(value):
		0: result += "0" # it's not correct but works
		1: result += "I"
		2: result += "II"
		3: result += "III"
		4: result += "IV"
		5: result += "V"
		6: result += "VI"
		7: result += "VII"
		8: result += "VIII"
		9: result += "IX"
		10: result += "X"
		_: result += "?"
		
	return result



static func println(txt=""):
	print(txt)



static func shop(folders_number): # int 
	print("Welcome to shop 1 exit 2 medic's shop")
	for i in range(folders_number):
		print(str(i+3) + " folder ")
	print()


static func shop_folder(folder):  # ArrayList<Item> 
	print("Welcome to shop 1 exit ")
	var x = -1  # int
	for thing in folder: # Item 
		x += 1
		var info = []  # ArrayList<Integer> 

		for dice in thing.base_pool: # int
			info.add(dice)
		
		var info2 = [] # ArrayList<String> 
		for spell in thing.magic_pool:  # Effect 
			info2.add(spell.short_print())
		
		# printing details about items
		#printf("%-16s", x+2 + " level: " + roman_numbers(thing.level))
		#printf("%-12s", ("price: " + thing.level * Balance.medium))
		#printf("%-34s", ("STR_req: " + thing.STR_req + " AG_req: " + thing.AG_req + " INT_req: " + thing.INT_req))   # TODO FIX PRINTF
		#printf("%-70s", ("base: " + info))
		#printf("%-70s", ("Magic: " + info2))
		print()


static func medic(healing): # int[][] 
	var x = 4 # int 
	var text_info = "Welcome to medic's shop 1 exit  2 max_heal  3 auto_heal  "
	for item in healing:  # int[] 
		x += 1
		text_info += str(x) + " [heal: " + item[0] + " price: " + item[1] + "] "  # TODO item[0] will propably not work properly
	print(text_info)



static func choice(txt=null): # return int, input string
	if txt != null:
		print(txt)
	return input_system()


static func input_system(): # returns int
	# TODO create input catch, print what was catched then return it as integer
	return 0





static func exit(txt, type): # 2 stings
	print(txt)

	match (type):
		"quest_fail": pass #System.exit(3)
		"fight": pass #System.exit(666)
		_: pass #System.exit(1) # unknown reason
	print("exiting the game") # TODO Fix exit system
