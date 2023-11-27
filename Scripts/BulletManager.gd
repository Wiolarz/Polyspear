extends Node



func _on_player_bullet(pos, dir, ammo):
	if ammo == null:
		print("null bullet")
		return
	var bullet = ammo.instantiate() as Area2D

	bullet.position = pos
	bullet.rotation_degrees = dir 
	add_child(bullet)
