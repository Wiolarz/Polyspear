class_name Goods
extends Resource

@export var wood : int = 0
@export var iron : int = 0
@export var ruby : int = 0

func _init(wood_ : int = 0, iron_ : int = 0, ruby_ : int = 0):
	wood = wood_
	iron = iron_
	ruby = ruby_


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


func to_array() -> Array[int]:
	return [wood, iron, ruby]
