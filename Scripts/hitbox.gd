extends Area2D


@export var max_health = [100, 50, 20]
var cur_health = max_health

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func damage(bullet):
	if bullet.is_class(Bullet):
		for plate in range(bullet.armor_pierce - 1):
			cur_health[plate] = min(cur_health[plate], bullet.damage)
			


