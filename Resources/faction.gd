class_name Faction

extends Resource

"""
Complete Faction data:
	1 Placement of every tile type
	2 Info about assignment of every city
"""


@export var units : Array[PackedScene] = [null]

@export var heroes : Array[PackedScene] = [null]

@export var city : PackedScene

