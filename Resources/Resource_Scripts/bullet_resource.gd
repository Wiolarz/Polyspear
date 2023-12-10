extends Resource

class_name bullet_resource



@export_category("Main Category")

#@export var ammo_type : GlobalTypes.Bullets = GlobalTypes.Bullets.DEFAULT



@export var ammo_type : GlobalTypes.Bullets = GlobalTypes.Bullets.DEFAULT



@export var damage : int = 10
@export var armor_pierce : int = 2
@export var explosion_dmg : int = 10

@export var bullet_sprite : Texture


@export_category("Properties Category")
@export var speed : int = 4

@export var death_timer : int = 6000