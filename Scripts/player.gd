extends CharacterBody2D

@export var max_speed = 200.0
@export var speedup = 5.0
@export var hor_speed = 1.0  # multiplier
@export var ver_speed = 0.5 # multiplier

@export var cheat_codes = false

# additional engines that quickly stop the spaceship, but duo to overheating the cannot be used as normal engines
@export var ship_break_power = 40.0  # speed power
@export var ship_break_cooldown = 20 #
var ship_break_timer = 0
@export var ship_break_max_charges = 20 #
var ship_break_charges = ship_break_max_charges
@export var ship_break_free_treshold = 10 # number we use to divide break power, to check if player can be awarded with free break



signal bullet(pos, dir, ammo)




func _ready():
	pass 

func cheats():
	if Input.is_action_just_pressed("CHEAT_IMMORTALITY"):
		if cheat_codes:
			cheat_codes = false
		else:
			cheat_codes = true


func movement():
	# BREAKS
	if Input.is_action_pressed("KEY_BREAKS") and ship_break_charges > 0:
		if velocity.x > ship_break_power / 10:
			velocity.x = clamp(velocity.x - ship_break_power, 0, velocity.x)
			ship_break_charges -= 1
		elif velocity.x < -(ship_break_power / 10):
			velocity.x = clamp(velocity.x + ship_break_power, velocity.x, 0)
			ship_break_charges -= 1
		else:  # we don't want to waste break charges for small usage
			velocity.x = 0
		
		if velocity.y > ship_break_power / 10:
			velocity.y = clamp(velocity.y - ship_break_power, 0, velocity.y)
			ship_break_charges -= 1
		elif velocity.y < -(ship_break_power / 10):
			velocity.y = clamp(velocity.y + ship_break_power, velocity.y, 0)
			ship_break_charges -= 1
		else:  # we don't want to waste break charges for small usage
			velocity.y = 0


	# MOVEMENT
	velocity.x = clamp(velocity.x + speedup * hor_speed * Input.get_axis("KEY_LEFT", "KEY_RIGHT"), -max_speed, max_speed)
	velocity.y = clamp(velocity.y + speedup * ver_speed * Input.get_axis("KEY_UP", "KEY_DOWN"), -max_speed, max_speed)

	#print(velocity)

	move_and_slide()

func recharge():
	#print(ship_break_charges)
	if ship_break_charges < ship_break_max_charges:
		ship_break_timer += 1
		if ship_break_timer == ship_break_cooldown:
			ship_break_charges += 1
			ship_break_timer = 0



func _physics_process(delta):
	cheats()
	movement()
	recharge()


func _on_gun_turret_turret_shoots(pos, dir, ammo):
	emit_signal("bullet", pos, dir, ammo)
