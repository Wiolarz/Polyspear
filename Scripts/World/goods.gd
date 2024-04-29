class_name Goods
extends Resource

@export var wood : int = 0
@export var iron : int = 0
@export var ruby : int = 0

func _init(new_wood: int = 0, new_iron : int = 0, new_ruby : int = 0):
	wood = new_wood
	iron = new_iron
	ruby = new_ruby


func has_enough(needed : Goods):
	return  wood >= needed.wood and \
			iron >= needed.iron and \
			ruby >= needed.ruby


func subtract(cost : Goods):
	wood -= cost.wood
	iron -= cost.iron
	ruby -= cost.ruby


func add(resource : Goods):
	wood += resource.wood
	iron += resource.iron
	ruby += resource.ruby


func clear():
	wood = 0
	iron = 0
	ruby = 0

func to_string_short(empty: String = "") -> String:
	if wood == 0 and iron == 0 and ruby == 0:
		return empty
	var result = ""
	if wood != 0:
		result += "%d 🪓" % wood
	if iron != 0:
		if result != "":
			result += " | "
		result += "%d ⛏️" % iron
	if ruby != 0:
		if result != "":
			result += " | "
		result += "%d 💎" % ruby
	return result

func _to_string() -> String:
	return "%d 🪓| %d ⛏️| %d 💎" % to_array()

func to_array() -> Array[int]:
	return [wood, iron, ruby]
