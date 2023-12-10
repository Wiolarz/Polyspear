extends Area2D

class_name hitbox


@export var max_health : Array[int] = [10, 5, 2]

@export var testhp1 : int = 5
@export var testhp2 : int = 5


var cur_health = max_health

func _ready():
	print(testhp1)
	print(testhp2)
	max_health[0] = testhp1
	max_health[1] = testhp2


func destruction():
	pass


func damage(bullet):
	#if bullet.is_class(Bullet):
	print(cur_health)
	var pierced_plates = 0  # value by which bullet is weakened if it managed to pierce the ship
	for plate in range(bullet.armor_pierce):  # depending on bullet piercing power, it damages more plates
		if plate >= cur_health.size():
			break
		pierced_plates += 1
		cur_health[plate] -= bullet.damage
	
	bullet.scrape(pierced_plates)
	
	print(cur_health)
	if cur_health[-1] <= 0:
		destruction()
		return
	

	# PLATES REMOVAL
	# could be replaced with simply skipping 0HP plates
	var to_be_removed = []
	
	for i in range(cur_health.size()):
		if cur_health[i] <= 0:
			to_be_removed.append(i)
	
	var i = 0
	for removal in to_be_removed:
		cur_health.pop_at(removal - i)
		i += 1


	
	
			
