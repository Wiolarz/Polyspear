extends hitbox

signal death()



@export var gun_turrets_sizes : Array[GlobalTypes.Turrets]


@onready var gun_turrets_placements = $GunTurrets.get_children()


func destruction():
	#print("emit death")
	emit_signal("death")
