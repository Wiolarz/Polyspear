class_name Unit

extends Node2D

@export var unit_stats : DataUnit

var unit_rotation : int
var coord : Vector2i
var controller : Player

## based on specific Unit scene in _ready() symbols get placed into their spots
var symbols : Array[E.Symbols] = [
	E.Symbols.EMPTY, E.Symbols.EMPTY, E.Symbols.EMPTY,
	E.Symbols.EMPTY, E.Symbols.EMPTY, E.Symbols.EMPTY,
]

var _target_tile : HexTile
var _move_speed : float

var _target_rotation_degrees : float
var _rotation_speed : float



func _physics_process(_delta):
	if 0.1 < abs(fmod(rotation_degrees, 360) - _target_rotation_degrees):
		_animate_rotation()
		return # so that unit first rotates then moves

	if _target_tile != null:
		_animate_movement()


func turn(side : int, skip_animation = false):
	"""
	  360 / 6 = 60  degrees needed to rotate unit

	  param Unit - Reference to the object we are rotating
	  param Direction
	"""
	unit_rotation = side

	_target_rotation_degrees = (60 * (side))
	if skip_animation \
			or CFG.animation_speed_frames == CFG.AnimationSpeed.INSTANT:
		rotation_degrees = _target_rotation_degrees
		$sprite_unit.rotation = -rotation
		return
	var current_rotation_degrees = fmod(rotation_degrees + 360, 360)
	var relative_rotation = _target_rotation_degrees - current_rotation_degrees
	_rotation_speed = abs(relative_rotation) / CFG.animation_speed_frames


func move(target : HexTile):
	_target_tile = target
	_move_speed = (target.position - position).length() / CFG.animation_speed_frames


func _animate_rotation():
	var current_rotation_degrees = fmod(rotation_degrees + 360, 360)
	var relative_rotation = _target_rotation_degrees - current_rotation_degrees
	#print(relative_rotation, "  ", p_direction, "   ", current_rotation)
	if relative_rotation < 0:
		relative_rotation += 360
	if relative_rotation > 180:
		relative_rotation -= 360
	var this_frame_rotation = clamp(relative_rotation, -1, 1) * _rotation_speed
	if abs(relative_rotation) < abs(this_frame_rotation):
		rotation = deg_to_rad(_target_rotation_degrees)
	else:
		rotation += deg_to_rad(this_frame_rotation)
	$sprite_unit.rotation = -rotation

func _animate_movement():
	if CFG.animation_speed_frames == CFG.AnimationSpeed.INSTANT:
		position = _target_tile.position
	else:
		position = position.move_toward(_target_tile.position, _move_speed)
	if (position - _target_tile.position).length_squared() < 0.01:
		position = _target_tile.position
		_target_tile = null


func can_defend(side : int) -> bool:
	return get_symbol(side) == E.Symbols.SHIELD


func get_symbol(side : int) -> E.Symbols:
	return symbols[(side - unit_rotation) % 6]


func set_selected(is_selected : bool):
	var c = Color.RED if is_selected else Color.WHITE
	$sprite_unit.modulate = c

func apply_template(data_template : DataUnit):
	unit_stats = data_template
	get_node("sprite_unit").texture = load(data_template.texture_path)
	for dir in range(0,6):
		symbols[dir] = unit_stats.symbols[dir].type
		#print("dir ",dir," template ",unit_stats.symbols[dir].type, " set ",Symbols[dir] )
		var symbol_sprite = get_node("Symbols")\
			.get_children()[dir].get_child(0).get_child(0)
		var tex = unit_stats.symbols[dir].texture_path
		if ( tex == null or tex == ""):
			symbol_sprite.hide()
		else:
			symbol_sprite.texture = load(tex)
			symbol_sprite.show()


func destroy():
	queue_free()


## WARNING: only for UNIT EDITOR
func _apply_symbol_sprite(dir : int, texture_path : String) -> void:
	var symbol_sprite = $"Symbols".get_children()[dir].get_child(0).get_child(0)
	if texture_path == null or texture_path.is_empty():
		symbol_sprite.texture = null
		symbol_sprite.hide()
		return
	symbol_sprite.texture = load(texture_path)
	symbol_sprite.show()


## WARNING: only for UNIT EDITOR
func _apply_unit_texture(texture : Texture2D) -> void:
	$sprite_unit.texture = texture
