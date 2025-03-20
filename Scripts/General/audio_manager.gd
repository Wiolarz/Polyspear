# AUDIO - singleton
class_name AudioManager
extends Node


@onready var sounds : Dictionary = {
	"click": $Click
}

func _init():
	get_tree().node_added.connect(_node_added)


func play(name : String):
	assert(sounds.get(name) != null, "Unknown sound '%s'" % [name])
	sounds[name].play()


## Automatically bind sounds to all known UI elements
func _node_added(node : Node):
	if node is Button:
		node.pressed.connect(play.bind("click"))

