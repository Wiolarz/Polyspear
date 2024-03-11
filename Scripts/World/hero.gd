extends Node


class_name Hero


@export var controller : Player

var cord : Vector2i

#@export var army : Array[PackedScene]
@export var army : UnitSet

var max_movement_points = 3
var movement_points = 3

func _init():
    controller = Player.new()


func trade(another_hero : Hero):
    print("trade menu")