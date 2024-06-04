class_name UnitForm
extends Node2D

signal anim_end()

var unit : Unit

var _target_tile : TileForm
var _move_speed : float

var _play_turn_anim : bool
var _target_rotation_degrees : float
var _rotation_speed : float

var _play_death_anim : bool

var _symbols_flipped : bool = true  # flag used for unit rotation

static func create(new_unit : Unit) -> UnitForm:
	var result = CFG.UNIT_FORM_SCENE.instantiate()
	result.name = new_unit.template.unit_name
	result.unit = new_unit

	result.apply_graphics(new_unit.template,
			new_unit.get_player_color())

	result.global_position = BM.get_tile(new_unit.coord).global_position
	result.rotation_degrees = new_unit.unit_rotation * 60
	result._target_rotation_degrees = result.rotation_degrees
	result.get_node("sprite_unit").rotation = -result.rotation


	return result

## HACK, this is for visuals only for summon UI
## no underlying Unit exists
static func create_for_summon_ui(template: DataUnit, color : DataPlayerColor) -> UnitForm:
	var result = CFG.UNIT_FORM_SCENE.instantiate()
	result.apply_graphics(template, color)
	return result


func _physics_process(delta):
	if _animate_rotation():
		return
	if _animate_movement():
		return
	_animate_death(delta)


func start_turn_anim():
	print("start turn anim")
	_play_turn_anim = true
	var new_side = unit.unit_rotation
	_target_rotation_degrees = (60 * (new_side))

	var current_rotation_degrees = fmod(rotation_degrees + 360, 360)
	var relative_rotation = _target_rotation_degrees - current_rotation_degrees
	_rotation_speed = abs(relative_rotation) / CFG.animation_speed_frames


func start_move_anim():
	print("start move anim")

	var new_coord = unit.coord
	var tile = BM.get_tile(new_coord)

	_target_tile = tile
	_move_speed = (tile.global_position - global_position).length() / CFG.animation_speed_frames
	print(global_position, " to ", tile.global_position, " coord ", new_coord )


func start_death_anim():
	print("start death anim")
	_play_death_anim = true



func update_movement_immediately():
	var coord = unit.coord
	var tile = BM.get_tile(coord)
	global_position = tile.global_position
	_target_tile = null


func update_turn_immediately():
	var side = unit.unit_rotation
	_target_rotation_degrees = (60 * (side))
	rotation_degrees = _target_rotation_degrees
	$sprite_unit.rotation = -rotation
	_rotation_symbol_flip()


func update_death_immediately():
	# TODO maybe check if unit is dead??
	scale = Vector2(0.0, 0.0)


func _rotation_symbol_flip():
	_symbols_flipped = true

	for dir in range(6):
		var symbol_sprite = $"Symbols".get_children()[dir].get_child(0).get_child(0)
		if symbol_sprite.texture == null:
			continue
		_flip_symbol_sprite(symbol_sprite, dir)


func _animate_rotation() -> bool:
	if not _play_turn_anim:
		_symbols_flipped = false
		return false

	if not _symbols_flipped:
		_rotation_symbol_flip()

	if CFG.animation_speed_frames == CFG.AnimationSpeed.INSTANT:
		rotation_degrees = _target_rotation_degrees
		$sprite_unit.rotation = -rotation
		print("instant turn end")
		anim_end.emit()
		_play_turn_anim = false
		return true

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


	if abs(fposmod(rotation_degrees, 360) - _target_rotation_degrees) < 0.1:
		print("normal turn end")
		anim_end.emit()
		_play_turn_anim = false
	return true


func _animate_movement() -> bool:
	if _target_tile == null:
		return false

	if CFG.animation_speed_frames == CFG.AnimationSpeed.INSTANT:
		global_position = _target_tile.global_position
		_target_tile = null
		print("instant move end")
		anim_end.emit()
		return true

	global_position = global_position.move_toward(_target_tile.global_position, _move_speed)
	if (global_position - _target_tile.global_position).length_squared() < 0.01:
		global_position = _target_tile.global_position
		_target_tile = null
		print("normal move end")
		anim_end.emit()
	return true


func _animate_death(delta) -> bool:
	if not _play_death_anim:
		return false

	scale.x -= 3 * delta
	if scale.x < 0:
		scale.x = 0
		_play_death_anim = false
		print("death anim end")
		anim_end.emit()
	scale.y = scale.x
	return true


func set_selected(is_selected : bool):
	var c = Color.RED if is_selected else Color.WHITE
	$sprite_unit.modulate = c


func apply_graphics(template : DataUnit, color : DataPlayerColor):
	var unit_texture = load(template.texture_path) as Texture2D
	_apply_unit_texture(unit_texture)
	_apply_color_texture(color)
	for dir in range(0,6):
		var symbol_texture = template.symbols[dir].texture_path
		_apply_symbol_sprite(dir, symbol_texture)


## WARNING: called directly in UNIT EDITOR
func _apply_symbol_sprite(dir : int, texture_path : String) -> void:
	var symbol_sprite = $"Symbols".get_children()[dir].get_child(0).get_child(0)
	if texture_path == null or texture_path.is_empty():
		symbol_sprite.texture = null
		symbol_sprite.hide()
		return
	symbol_sprite.texture = load(texture_path)

	_flip_symbol_sprite(symbol_sprite, dir)

	symbol_sprite.show()


## Flips ths sprite so that weapons always point to the top of the screen
func _flip_symbol_sprite(symbol_sprite : Sprite2D, dir : int):
	var abstract_rotation : int = 0
	if unit != null:
		abstract_rotation = (unit.unit_rotation + dir) % 6
	if abstract_rotation in [0, 1, 5]:  # LEFT
		symbol_sprite.flip_v = false
	else:
		symbol_sprite.flip_v = true


## WARNING: called directly in UNIT EDITOR
func _apply_unit_texture(texture : Texture2D) -> void:
	$sprite_unit.texture = texture


func _apply_color_texture(color : DataPlayerColor) -> void:
	var color_texture_name : String = color.hexagon_texture
	var path = "res://Art/player_colors/%s.png" % color_texture_name
	var texture = load(path) as Texture2D
	assert(texture, "failed to load background " + path)
	$sprite_color.texture = texture

