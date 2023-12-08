extends Node2D

class_name Gun

@export var shooting_speed = 10  # frames between shoots
var shooting_cooldown = 0

@export var reload_time = 100
@export var max_ammunition = 10
@export var ammuniton = 10

#var acceptable_bullets = ["default"]

var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")



func shoot():
	if ammuniton == 0:
		return "no_ammo"
	
	if shooting_cooldown == 0:
		ammuniton -= 1
		shooting_cooldown = shooting_speed
		return bullet_scene
	return "cooldown"


func reload(avalaible_ammo):
	"""
	Takes number of bullets turret has
	
	"""
	shooting_cooldown = reload_time
	ammuniton = min(max_ammunition, avalaible_ammo)
	return ammuniton


func _physics_process(_delta):
	if shooting_cooldown > 0:
		shooting_cooldown -= 1
