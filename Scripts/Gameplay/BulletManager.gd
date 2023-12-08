extends Node



func _on_player_bullet(pos, dir, ammo, bullet_owner):
	if ammo == null:
		print("null bullet")
		return
	var bullet = ammo.instantiate() as Area2D
	bullet.bullet_owner = bullet_owner
	bullet.position = pos
	bullet.rotation_degrees = dir 
	add_child(bullet)
