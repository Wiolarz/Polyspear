class_name Hero
extends Node

@export var army : Army

var controller : Player



var cord : Vector2i

var max_movement_points = 3
var movement_points = 3


var target_tile : HexTile


func trade(another_hero : Hero):
	print("trade menu")


func move(target : HexTile):
	target_tile = target

