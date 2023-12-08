extends Node2D




func _process(_delta):
	position.x -= 1



func _on_hitbox_death():
	queue_free()
