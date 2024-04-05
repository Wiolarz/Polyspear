class_name AUnit

extends Node2D

@export var unitStats : DataUnit

var unit_rotation : int
var cord : Vector2i
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

func turn(side : int):
	"""
	  360 / 6 = 60  degrees needed to rotate unit
	  
	  param Unit - Reference to the object we are rotating
	  param Direction
	"""
	unit_rotation = side
	
	# 360 / 6 = 60 -> degrees needed to rotate unit
	# "Direction + 4" Accounts for global rotation setting for objects in the level
	rotation = deg_to_rad((60 * (side)))
	#print(rotation, "   ", target_rotation)

func move(target : HexTile):
	target_tile = target

func _physics_process(_delta):
	#if target_rotation != rotation:
		#rotation = move_toward(rotation, target_rotation, 0.1)
	
	if target_tile != null:
		if BUS.animation_speed == BUS.animation_speed_values.INSTANT:
			position = target_tile.position
		else:
			position = position.move_toward(target_tile.position, BUS.animation_speed)
		#position.x = move_toward(position.x, target_tile.position.x, BUS.animation_speed)
		#position.y = move_toward(position.y, target_tile.position.y, BUS.animation_speed)
		if position.x == target_tile.position.x and position.y == target_tile.position.y:
			target_tile = null

func set_selected(isSelected:bool):
	var c = Color.RED if isSelected else Color.WHITE
	$sprite_unit.modulate = c

func apply_template(dataTemplate : DataUnit):
	unitStats = dataTemplate
	get_node("sprite_unit").texture = load(dataTemplate.texture_path)
	for dir in range(0,6):
		Symbols[dir] = unitStats.symbols[dir].type
		print("dir ",dir," template ",unitStats.symbols[dir].type, " set ",Symbols[dir] )
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
