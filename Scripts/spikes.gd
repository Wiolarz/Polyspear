extends Area2D


# default time between damage ticks for all weapons. (60 frames = 1 second)
@export var immunity_frames = 180


@export var damage_value = 20



#enum weapons_properties {IMMUNE_TIMER, PLUNGED} # doesnt work for some reason

# List of all bodies that weapon has pierced
var plunged_bodies = {}



func _physics_process(_delta):
	for body in plunged_bodies.keys():
		var immune = clamp(0, plunged_bodies[body]["IMMUNE_TIMER"] - 1, immunity_frames)
		plunged_bodies[body]["IMMUNE_TIMER"] = immune

		if plunged_bodies[body]["PLUNGED"] and immune == 0:
			body.damage(hit())
			plunged_bodies[body]["IMMUNE_TIMER"] = immunity_frames


func hit():
	return damage_value


func _on_area_entered(area:Area2D):
	if area.has_method("damage"):
		area.damage(hit())
		plunged_bodies[area] = {"IMMUNE_TIMER" = immunity_frames, "PLUNGED" = true}


func _on_area_exited(area:Area2D):
	if area.has_method("damage"):
		plunged_bodies[area]["PLUNGED"] = false

