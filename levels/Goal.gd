extends Area2D



func _on_area_entered(area):
	if area.get_name() == "PlayerShape": 
		print("You won")
		get_tree().reload_current_scene()




