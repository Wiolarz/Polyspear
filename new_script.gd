var knight_equipment = {
	"sword": {"name": "Iron Sword", "damage": 10, "durability": 100},
	"shield": {"name": "Wooden Shield", "defense": 5, "durability": 50}
}


func _ready():
	print("Welcome, blacksmith! You are in charge of managing your knight's equipment.")


func _process(_delta):
	var input = get_input()
	if input:
		process_input(input)


func get_input():
	var input = "test"  # input
	if input != "":
		return input.strip().lower()
	return null


func process_input(input):
	var args = input.split(" ")
	var command = args[0]
	if command == "help":
		print_help()
	elif command == "equip":
		equip_item(args)
	elif command == "repair":
		repair_item(args)
	elif command == "stats":
		print_stats()
	else:
		print("Invalid command. Type 'help' for a list of commands.")


func print_help():
	print("Commands:")
	print("equip [item] - equip an item from your inventory")
	print("repair [item] - repair an item in your inventory")
	print("stats - show the current stats of your knight's equipment")
	print("help - show this help message")


func equip_item(args):
	if args.length() < 2:
		print("Please specify an item to equip.")
		return
	var item = args[1]
	if item in knight_equipment:
		print("Equipped " + knight_equipment[item]["name"])
	else:
		print("Invalid item.")


func repair_item(args):
	if args.length() < 2:
		print("Please specify an item to repair.")
		return
	var item = args[1]
	if item in knight_equipment:
		knight_equipment[item]["durability"] = 100
		print("Repaired " + knight_equipment[item]["name"])
	else:
		print("Invalid item.")


func print_stats():
	print("Knight's Equipment Stats:")
	for item in knight_equipment:
		var stats = []
		if "damage" in knight_equipment[item]:
			stats.append("Damage: " + str(knight_equipment[item]["damage"]))
		if "defense" in knight_equipment[item]:
			stats.append("Defense: " + str(knight_equipment[item]["defense"]))
		stats.append("Durability: " + str(knight_equipment[item]["durability"]))
		print(knight_equipment[item]["name"] + " - " + ", ".join(stats))
