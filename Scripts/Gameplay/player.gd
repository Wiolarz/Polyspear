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



signal bullet(pos, dir, bullet_scene, bullet_owner)


func _ready():
	Bus.load_game.connect(load_self)
	Bus.collect_save_data.connect(save_self)
	Bus.player_reference = self


func load_self(save: Save):
	position = save.ship_position
	$GunTurret/Guns/Gun.ammuniton = save.ship_ammunition
		
func save_self(save: Save):
	save.ship_position = position
	save.ship_ammunition = $GunTurret/Guns/Gun.ammuniton


"""
func save_ship():
	var player_dict = {
		"AMMO": $Guns/Gun.ammuniton,
	}

	return player_dict

func load_ship(loaded_player_data):
	$GunTurret/Guns/Gun.ammuniton = loaded_player_data.AMMO
"""

	

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

func break_recharge():
	#print(ship_break_charges)
	if ship_break_charges < ship_break_max_charges:
		ship_break_timer += 1
		if ship_break_timer == ship_break_cooldown:
			ship_break_charges += 1
			ship_break_timer = 0



func _physics_process(_delta):
	cheats()
	movement()
	break_recharge()


func _on_gun_turret_turret_shoots(pos, dir, bullet_sc):
	emit_signal("bullet", pos, dir, bullet_sc, $hitbox)


func _on_hitbox_death():

	Bus.player_reference = null
	queue_free()
