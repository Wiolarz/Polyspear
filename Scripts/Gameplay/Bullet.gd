extends Area2D

class_name Bullet

@export var resource : bullet_resource

@export var ammo_type = "Default"

@export var damage = 10
@export var armor_pierce = 2
@export var explosion_dmg = 10


@export var speed = 4

@export var death_timer = 10000
var velocity



var bullet_owner = null

# Called when the node enters the scene tree for the first time.
func _ready():
	#$Sprite2D.texture = resource.bullet_sprite
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	position += velocity
	death_timer -= 1
	if death_timer == 0:
		queue_free()



func _on_area_entered(area:Area2D):
	if area.has_method("damage") and not area.owner == bullet_owner:
		area.damage(self)


func scrape(plates_pierced):
	armor_pierce -= plates_pierced
	if armor_pierce <= 0:
		queue_free()
