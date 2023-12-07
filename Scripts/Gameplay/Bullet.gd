extends Area2D

class_name Bullet

@export var ammo_type = "Default"

@export var damage = 10
@export var armor_pierce = 2
@export var explosion_dmg = 10


@export var speed = 4
var velocity

var death_timer = 10000


# Called when the node enters the scene tree for the first time.
func _ready():
	
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	position += velocity
	death_timer -= 1
	if death_timer == 0:
		queue_free()



func _on_area_entered(area:Area2D):
	return
	if area.has_method("damage"):
		area.damage(self)
