extends gun_turret

#@onready var target = $"../../../Player"
@onready var target = Bus.player_reference


func _physics_process(_delta):
	if target == null:
		return
	look_at(target.global_position)
	super.shoot()
	#look_at(get_tree().get_root().get_node("Player").global_position)
	#look_at(get_tree().get_node("Player").global_position)
