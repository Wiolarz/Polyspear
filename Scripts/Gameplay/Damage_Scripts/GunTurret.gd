extends Node2D

class_name gun_turret

signal turret_shoots(pos, dir, ammo)




@export var turret_size : GlobalTypes.Turrets = GlobalTypes.Turrets.MEDIUM


@export var gun_res : Array[gun_resource]


@export var gun_slots : Array[GlobalTypes.Guns]




@export var ammuniton = 1000

@onready var rifle_exits : Array[Node] = $Barrels.get_children()


#@onready var guns : Node2D = $Guns

#@onready var current_gun = $Guns.get_children(0)
@export var current_gun : Gun


func _ready():
	current_gun.change_stats(gun_res[0])


func shoot():
	if not current_gun:
		print("ERROR: GunTurret.shoot()")
		return
	
	var bullet = current_gun.shoot()
	if bullet is String:
		if bullet == "cooldown":
			return
		elif bullet == "no_ammo":
			ammuniton -= current_gun.reload(ammuniton)
			return
	
	#print("GunTurret shoots")
	emit_signal("turret_shoots", rifle_exits[0].global_position, rotation_degrees, bullet)




