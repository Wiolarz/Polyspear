extends Node2D


signal turret_shoots(pos, dir, ammo)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	look_at(get_global_mouse_position())
	#rotation = get_global_mouse_position().angle_to_point(global_position)


func _on_gun_gun_shoots(pos, ammo):
	emit_signal("turret_shoots", pos, rotation_degrees, ammo)
