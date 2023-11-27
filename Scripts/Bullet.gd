extends Area2D


@export var damage = 10
@export var armor_pierce = 2
@export var explosion_dmg = 10


@export var speed = 4
var velocity
# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	position += velocity

