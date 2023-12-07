extends Node2D


signal turret_shoots(pos, dir, ammo)

@export var ammuniton = 1000


@onready var rifle_exit: Marker2D = $Marker2D

#@onready var guns : Node2D = $Guns

#@onready var current_gun = $Guns.get_children(0)
@export var current_gun : Gun


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
	
	emit_signal("turret_shoots", rifle_exit.global_position, rotation_degrees, bullet)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	look_at(get_global_mouse_position())


	if Input.is_action_pressed("KEY_SHOOT"):
		shoot()
		
	#rotation = get_global_mouse_position().angle_to_point(global_position)