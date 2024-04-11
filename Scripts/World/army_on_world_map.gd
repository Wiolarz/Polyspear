class_name ArmyOnWorldMap
extends Node2D

var army_data: Army = Army.new()

var cord: 
	get: return army_data.cord

var controller:
	get: return army_data.controller

func _ready():
	army_data.hero = Hero.new()
	army_data.hero.controller = army_data.controller
	
func move(tile):
	position = tile.position
	army_data.cord = tile.cord

func set_selected(is_selected : bool) -> void:
	$sprite_color.modulate = Color.RED if is_selected else Color.WHITE
