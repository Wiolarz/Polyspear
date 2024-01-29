extends Node2D

class_name AUnit

var CurrentRotation : int
var CurrentCord : Vector2i
var Controller : E.Player

@export var Symbols : Array[E.Symbols] = [ \
	E.Symbols.INVALID, E.Symbols.INVALID, E.Symbols.INVALID,
	E.Symbols.INVALID, E.Symbols.INVALID, E.Symbols.INVALID]




func GetSymbol(side) -> E.Symbols:
	return Symbols[(side - CurrentRotation) % 6]

func Rotate(side):
	"""
	  360 / 6 = 60  degrees needed to rotate unit
	  
	  param Unit - Reference to the object we are rotating
	  param Direction
	"""
	CurrentRotation = side
	
	# 360 / 6 = 60 -> degrees needed to rotate unit
	# "Direction + 4" Accounts for global rotation setting for objects in the level
	rotation = deg_to_rad((60 * (side - 2)) + 30)  # TODO: 4 is "magic number" -- ?grid rotation



func Destroy():
	queue_free()
