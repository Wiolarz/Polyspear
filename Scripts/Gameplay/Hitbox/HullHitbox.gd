extends hitbox

signal death()


func destruction():
	print("emit death")
	emit_signal("death")
