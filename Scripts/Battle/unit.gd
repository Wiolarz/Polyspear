class_name Unit

extends Node2D

@export var unitStats : DataUnit

var unit_rotation : int
var coord : Vector2i
var controller : Player

var Symbols : Array[E.Symbols] = [  # based on specific Unit scene in _ready() symbols get placed into their spots
	E.Symbols.EMPTY, E.Symbols.EMPTY, E.Symbols.EMPTY, 
	E.Symbols.EMPTY, E.Symbols.EMPTY, E.Symbols.EMPTY]

var target_tile : HexTile
var target_rotation = rotation


func can_defend(side : int) -> bool:
	return get_symbol(side) == E.Symbols.SHIELD
		

func get_symbol(side : int) -> E.Symbols:
	return Symbols[(side - unit_rotation) % 6]

func turn(side : int, skip_animation = false):
	"""
	  360 / 6 = 60  degrees needed to rotate unit
	  
	  param Unit - Reference to the object we are rotating
	  param Direction
	"""
	unit_rotation = side
	
	# 360 / 6 = 60 -> degrees needed to rotate unit
	# "Direction + 4" Accounts for global rotation setting for objects in the level

	target_rotation = (60 * (side))
	if skip_animation:
		rotation_degrees = target_rotation
		$sprite_unit.rotation = -rotation
	#rotation = deg_to_rad((60 * (side)))

	#print(rotation, "   ", target_rotation)

func move(target : HexTile):
	target_tile = target

func _physics_process(_delta):
	if 0.1 < abs(fmod(rotation_degrees, 360) - target_rotation):
		#var p_direction =
		#fmod(rad_to_deg(global_position.angle_to_point(player.global_position)) + 360, 360) # - 360
		# fmod = float modulo %

		var current_rotation = fmod(rotation_degrees + 360, 360)
		var relative_rotation = target_rotation - current_rotation


		#print(relative_rotation, "  ", p_direction, "   ", current_rotation)

		if relative_rotation < 0:
			relative_rotation += 360

		if relative_rotation > 180:
			relative_rotation -= 360




		#body.direction_change(clamp(relative_rotation, -1, 1))

		var rotation_speed = 5.0
		var this_frame_rotation = clamp(relative_rotation, -1, 1) * rotation_speed
		if abs(relative_rotation) < abs(this_frame_rotation):
			rotation = deg_to_rad(target_rotation)
		else:
			rotation += deg_to_rad(this_frame_rotation)
		#rotation = move_toward(rotation, target_rotation, 0.1)

		$sprite_unit.rotation = -rotation

		return # so that unit first rotates then moves
	
	if target_tile != null:
		if BUS.animation_speed == BUS.animation_speed_values.INSTANT:
			position = target_tile.position
		else:
			position = position.move_toward(target_tile.position, BUS.animation_speed)
		#position.x = move_toward(position.x, target_tile.position.x, BUS.animation_speed)
		#position.y = move_toward(position.y, target_tile.position.y, BUS.animation_speed)
		if (position - target_tile.position).length_squared() < 0.01:
			position = target_tile.position
			target_tile = null

func set_selected(isSelected:bool):
	var c = Color.RED if isSelected else Color.WHITE
	$sprite_unit.modulate = c

func apply_template(dataTemplate : DataUnit):
	unitStats = dataTemplate
	get_node("sprite_unit").texture = load(dataTemplate.texture_path)
	for dir in range(0,6):
		Symbols[dir] = unitStats.symbols[dir].type
		#print("dir ",dir," template ",unitStats.symbols[dir].type, " set ",Symbols[dir] )
		var symbol_sprite = get_node("Symbols")\
			.get_children()[dir].get_child(0).get_child(0)
		var tex = unitStats.symbols[dir].texture_path
		if ( tex == null or tex == ""):
			symbol_sprite.hide()
		else:
			symbol_sprite.texture = load(tex)
			symbol_sprite.show()

func destroy():
	queue_free()
