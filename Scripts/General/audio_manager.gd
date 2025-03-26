# AUDIO - singleton
class_name AudioManager
extends Node


## How to add new sounds: [br]
## 1. Add the sound file to one of Audio/* folders [br]
## 2. Add an AudioStreamPlayer (or AudioStreamPlayer2D) [br]
##    as a child node to Scenes/AudioManager.tscn [br]
##    Make sure to set appropriate *stream* and *bus*. [br] 
##    You also may (or may not) want to adjust volume and max polyphony [br]
## 3. Add an entry in a dictionary below


@onready var sounds : Dictionary = {
	"click": $Click
}

@onready var bus_idxs : Dictionary = {
	"volume_master": AudioServer.get_bus_index("Master"),
	"volume_music":  AudioServer.get_bus_index("Music"),
	"volume_game":   AudioServer.get_bus_index("Game"),
	"volume_ui":     AudioServer.get_bus_index("UI")
}


func _ready():
	get_tree().node_added.connect(_node_added)


func _process(_delta : float):
	for name in bus_idxs:
		var volume_slider = CFG.player_options.get(name)
		var volume_linear = volume_slider/100.0
		var volume_db = 10.0 * log(volume_linear) / log(2)
		AudioServer.set_bus_volume_db(bus_idxs[name], volume_db)


func play(name : String):
	assert(sounds.get(name) != null, "Unknown sound '%s'" % [name])
	sounds[name].play()


## Automatically bind sounds to all newly created UI elements
func _node_added(node : Node):
	if node is Button:
		node.pressed.connect(play.bind("click"))
	if node is TabBar:
		node.tab_changed.connect(func(_idx): play("click"))
