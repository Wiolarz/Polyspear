extends Resource

class_name gun_resource


@export var shooting_speed = 10  # frames between shoots
var shooting_cooldown = 0

@export var reload_time = 100
@export var max_ammunition = 10
@export var ammuniton = 10

#var acceptable_bullets = ["default"]

var bullet_scene: PackedScene = preload("res://Scenes/bullet.tscn")



@export_category("Main Category")
# TODO one bullet type per weapon, in future it will be expanded to allow player to choose which ammo type apply to which gun
@export var ammo_type : GlobalTypes.Bullets = GlobalTypes.Bullets.DEFAULT

@export var damage : int = 10
@export var armor_pierce : int = 2
@export var explosion_dmg : int = 10

@export var bullet_sprite : Texture


@export_category("Properties Category")
@export var speed : int = 4

@export var death_timer : int = 6000