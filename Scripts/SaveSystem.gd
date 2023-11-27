extends Node


@export var reset_save = false

var player_file = "user://save.dat"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass#Bus.save.connect(save)


func save():
	var save = Save.new()
	save.position = get_node("%Player").position
