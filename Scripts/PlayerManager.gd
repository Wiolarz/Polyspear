extends Node2D

signal HPchanged(new_value, max_value)

@export var max_health = 200
@export var health = 100
@export var regeneration_cooldown = 60  # in frames
@export var regeneration_power = 5  # points of HP
var regeneration_timer = 0


@export var cheats = false

func _ready():
	Score.level = 1
	Score.value = 0
	emit_signal("HPchanged", health, max_health)




func _process(_delta):
	if Input.is_action_just_pressed("CHEAT_CODES_LEVEL_UP"):
		Score.value += 50
	if Input.is_action_just_pressed("CHEAT_MODE"):
		if cheats:
			cheats = false
		else:
			cheats = true
	if Score.value >= 50:
		Score.level += 1
		Score.value = 0
		get_node("PlayerMovement").speed += 1
		get_node("Weapon/WeaponBody").rotation_speed += 0.25

func _physics_process(_delta):
	regeneration_timer += 1
	if regeneration_timer == regeneration_cooldown:
		regeneration_timer = 0
		health += regeneration_power
		if health > max_health:
			health = max_health
		emit_signal("HPchanged", health, max_health)


func _on_character_hitbox_got_hit(value):
	if not cheats:
		health -= value
		emit_signal("HPchanged", health, max_health)
		#print("player", health)


	if health <= 0:
		get_tree().reload_current_scene()



