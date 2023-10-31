extends Area2D

@export var max_damage = 999


func _on_area_entered(area:Area2D):
	if area.has_method("damage"):
		area.damage(max_damage)
