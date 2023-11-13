extends CanvasLayer

@export var player : Node2D

@onready var hp_text = $RichTextLabel
@onready var hp_bar = $HPBar

# Called when the node enters the scene tree for the first time.
func _ready():
	player.connect("HPchanged", HPchange)

	hp_text.text = "HP " + str(player.health)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	hp_text.text = "HP" + str(player.health)



func HPchange(new_value, max_value=null):
	hp_bar.display(new_value, max_value)