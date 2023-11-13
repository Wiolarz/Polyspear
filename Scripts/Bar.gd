extends Control

@onready var value_bar = $Value

var max_value = null

#var old_value = null # TODO

func display(new_value, max=null):
	if max_value == null:
		if max != null:
			max_value = max
		else:
			max_value = new_value
	
	var new_percantage = float(new_value) / max_value
	#print("max= ", max_value, " val=", new_value)
	#print(new_percantage)
	value_bar.scale.x = new_percantage
	
		



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
