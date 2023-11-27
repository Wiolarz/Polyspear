extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass




func _on_player_bullet(pos, dir, ammo):
	var bullet = ammo.instantiate() as Area2D
	#bullet.position = rifle_exit.global_position()
	print("test")
	print(pos, dir)

	bullet.position = pos
	bullet.rotation_degrees = dir # rotation_degrees#rad_to_deg(direction.angle())
	add_child(bullet) # get_tree().get_node("BasicMap").
