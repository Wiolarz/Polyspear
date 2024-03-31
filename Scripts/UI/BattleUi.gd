extends Control

@onready
var playersBox : BoxContainer = $Players

@onready
var unitsBox : BoxContainer = $Units

func _ready():
	var players = playersBox.get_children()
	players[2].queue_free()
	players[1].queue_free()
	var n = Button.new()
	n.text = "Player 1"
	n.pressed.connect(func p1(): onPlayerSelect(1))
	playersBox.add_child(n)
	var n2 = Button.new()
	n2.text = "Player 2"
	n2.pressed.connect(func p1(): onPlayerSelect(2))
	playersBox.add_child(n2)

func onPlayerSelect(playerId:int):
	for c in unitsBox.get_children():
		c.queue_free()
	var b = TextureButton.new()
	b.texture_normal = load( "res://Art/elf1.png" if playerId == 1 else  "res://Art/ork1.png" )
	b.add_child(load("res://Scenes/Units/elf/Archer.tscn").instantiate())
	unitsBox.add_child(b)



func _on_switch_camera_pressed():
	IM.switch_camera()
