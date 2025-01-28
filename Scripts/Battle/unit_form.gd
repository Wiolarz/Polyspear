class_name UnitForm
extends Node2D

## emitted when anim ends (move, turn, die)
signal anim_end()

const SIDE_NAMES = ["FrontSymbol", "FrontRightSymbol", "BackRightSymbol", "BackSymbol", "BackLeftSymbol", "FrontLeftSymbol"]

var entity : Unit

var _play_move_anim : bool
var _target_global_position : Vector2
var _move_speed : float

var _play_turn_anim : bool
var _target_rotation_degrees : float
var _rotation_speed : float

var _play_death_anim : bool

var _symbols_flipped : bool = true  # flag used for unit rotation


func _process(delta):
	if entity:
		$Symbols.modulate = Color.RED if entity.is_on_swamp else Color.WHITE
	if _animate_rotation():
		return
	if _animate_movement():
		return
	_animate_death(delta)


#region Init

static func create(new_unit : Unit) -> UnitForm:
	var result = CFG.UNIT_FORM_SCENE.instantiate()
	result.name = new_unit.template.unit_name
	result.entity = new_unit

	var color : DataPlayerColor
	if not new_unit.controller:
		color = CFG.NEUTRAL_COLOR
	else:
		color = new_unit.controller.get_player_color()

	result.apply_graphics(new_unit.template, color)

	result.global_position = BM.get_tile_global_position(new_unit.coord)
	result._target_global_position = result.global_position
	result.rotation_degrees = new_unit.unit_rotation * 60
	result._target_rotation_degrees = result.rotation_degrees
	result.get_node("sprite_unit").rotation = -result.rotation
	result.get_node("RigidUI").rotation = -result.rotation
	return result


## HACK, this is for visuals only for summon UI
## no underlying Unit exists
static func create_for_summon_ui(template: DataUnit, color : DataPlayerColor) -> UnitForm:
	var result = CFG.UNIT_FORM_SCENE.instantiate()
	result.apply_graphics(template, color)
	return result


func apply_graphics(template : DataUnit, color : DataPlayerColor):
	var unit_texture = load(template.texture_path) as Texture2D
	_apply_unit_texture(unit_texture)
	_apply_color_texture(color)
	_apply_level_number(template.level)
	for side in range(0,6):
		var symbol_texture = template.symbols[side].texture_path
		_apply_symbol_sprite(side, symbol_texture)
	
	_flip_unit_sprite()
	$RigidUI/SpellEffect1.texture = null
	$RigidUI/SpellEffect2.texture = null
	$RigidUI/SpellEffectCounter1.text = ""
	$RigidUI/SpellEffectCounter2.text = ""
	$RigidUI/TerrainEffect.texture = null


## WARNING: called directly in UNIT EDITOR
func _apply_symbol_sprite(side : int, texture_path : String) -> void:
	var sprite_path = "Symbols/%s/SymbolForm/Sprite2D" % [SIDE_NAMES[side]]
	var symbol_sprite = get_node(sprite_path)
	if texture_path == null or texture_path.is_empty():
		symbol_sprite.texture = null
		symbol_sprite.hide()
		return
	symbol_sprite.texture = load(texture_path)

	_flip_symbol_sprite(symbol_sprite, side)

	symbol_sprite.show()


## Flips ths sprite so that weapons always point to the top of the screen
func _flip_symbol_sprite(symbol_sprite : Sprite2D, dir : int):
	var abstract_rotation : int = 0
	if entity != null:
		abstract_rotation = (entity.unit_rotation + dir) % 6
	if abstract_rotation in [0, 1, 5]:  # LEFT
		symbol_sprite.flip_v = false
	else:
		symbol_sprite.flip_v = true

func _flip_unit_sprite():
	var abstract_rotation : int = 0
	if entity != null:
		abstract_rotation = (entity.unit_rotation) % 6
	if abstract_rotation in [0, 1, 5]:  # LEFT
		$sprite_unit.flip_h = false
	else:
		$sprite_unit.flip_h = true

## WARNING: called directly in UNIT EDITOR
func _apply_unit_texture(texture : Texture2D) -> void:
	$sprite_unit.texture = texture


func _apply_color_texture(color : DataPlayerColor) -> void:
	var color_texture_name : String = color.hexagon_texture
	var path = "%s%s.png" % [CFG.PLAYER_COLORS_PATH, color_texture_name]
	var texture = load(path) as Texture2D
	assert(texture, "failed to load background " + path)
	$sprite_color.texture = texture


func _apply_level_number(level : int) -> void:
	const roman_numbers = ["0", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	if level > 10 or level < 0:
		assert(false, "Design wise higher level units don't make sense")
		level = 1
	$RigidUI/UnitLevel.text = roman_numbers[level]

#endregion Init


func anim_move():
	var target = BM.get_tile_global_position(entity.coord)
	ANIM.main_tween().tween_property(self, "position", target, 0.3)

func anim_turn():
	var time = 0.3
	var angle_rel = angle_difference(rotation, deg_to_rad(entity.unit_rotation * 60))
	ANIM.main_tween().tween_property(self, "rotation", angle_rel, time).as_relative()
	ANIM.main_tween().parallel().tween_property($sprite_unit, "rotation", -angle_rel, time).as_relative()
	ANIM.main_tween().parallel().tween_property($RigidUI, "rotation", -angle_rel, time).as_relative()
	_rotation_symbol_flip()
	_flip_unit_sprite()

func anim_die():
	ANIM.main_tween().tween_property(self, "scale", Vector2.ZERO, 0.3)
	ANIM.main_tween().tween_callback(queue_free)

func anim_symbol(side: int):
	var side_local : int = GenericHexGrid.rotate_clockwise( \
			side as GenericHexGrid.GridDirections, -entity.unit_rotation)
	var symbol = get_node("Symbols/%s/SymbolForm" % SIDE_NAMES[side_local])
	var tween = ANIM.subtween()
	tween.tween_property(symbol, "scale", Vector2(2.0, 2.0), 0.0)
	tween.tween_property(symbol, "scale", Vector2(1.0, 1.0), 0.5)

func anim_magic():
	# TODO
	pass

#region Instant Animation Mode
## Used only when animation speed is set to instant

func update_movement_immediately():
	var tile_position = BM.get_tile_global_position(entity.coord)
	global_position = tile_position


func update_turn_immediately():
	var side = entity.unit_rotation
	_target_rotation_degrees = (60 * (side))
	rotation_degrees = _target_rotation_degrees
	$sprite_unit.rotation = -rotation
	$RigidUI.rotation = -rotation
	_rotation_symbol_flip()
	_flip_unit_sprite()


func update_death_immediately():
	# TODO maybe check if unit is dead??
	scale = Vector2(0.0, 0.0)

#endregion Instant Animation Mode


#region Animations

func _rotation_symbol_flip():
	_symbols_flipped = true

	for dir in range(6):
		var symbol_sprite = $"Symbols".get_children()[dir].get_child(0).get_child(0)
		if symbol_sprite.texture == null:
			continue
		_flip_symbol_sprite(symbol_sprite, dir)


func start_turn_anim():
	print("start turn anim")
	_play_turn_anim = true
	var new_side = entity.unit_rotation
	_target_rotation_degrees = (60 * (new_side))

	var current_rotation_degrees = fmod(rotation_degrees + 360, 360)
	var relative_rotation = _target_rotation_degrees - current_rotation_degrees
	_rotation_speed = abs(relative_rotation) / CFG.animation_speed_frames


func start_move_anim():
	print("start move anim")
	_play_move_anim = true
	var new_coord = entity.coord
	_target_global_position = BM.get_tile_global_position(new_coord)
	_move_speed = (_target_global_position - global_position).length() / CFG.animation_speed_frames
	print("move from ", global_position, " to ", _target_global_position, " coord ", new_coord )


func start_death_anim():
	print("start death anim")
	_play_death_anim = true


func _animate_rotation() -> bool:
	if not _play_turn_anim:
		_symbols_flipped = false
		return false

	if not _symbols_flipped:
		_rotation_symbol_flip()
		_flip_unit_sprite()

	if CFG.animation_speed_frames == CFG.AnimationSpeed.INSTANT:
		rotation_degrees = _target_rotation_degrees
		$sprite_unit.rotation = -rotation
		$RigidUI.rotation = -rotation
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
	$RigidUI.rotation = -rotation


	if abs(fposmod(rotation_degrees, 360) - _target_rotation_degrees) < 0.1:
		print("normal turn end")
		anim_end.emit()
		_play_turn_anim = false
	return true


func _animate_movement() -> bool:
	if not _play_move_anim:
		return false

	if CFG.animation_speed_frames == CFG.AnimationSpeed.INSTANT:
		global_position = _target_global_position
		_play_move_anim = false
		print("instant move end")
		anim_end.emit()
		return true

	global_position = global_position.move_toward(_target_global_position, _move_speed)
	if (global_position - _target_global_position).length_squared() < 0.01:
		global_position = _target_global_position
		_play_move_anim = false
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

#endregion Animations


#region UI

func set_effects() -> void:
	# Terrain effects
	if entity.is_on_swamp:
		$RigidUI/TerrainEffect.texture = load(CFG.SWAMP_ICON_PATH)
	elif entity.is_on_rock:
		$RigidUI/TerrainEffect.texture = load(CFG.ROCK_ICON_PATH)
	elif entity.is_on_mana:
		$RigidUI/TerrainEffect.texture = load(CFG.MANA_ICON_PATH)
	else:
		$RigidUI/TerrainEffect.texture = null

	# Magical effects
	var spell_effects_slots : Array[Sprite2D] = [$RigidUI/SpellEffect1, $RigidUI/SpellEffect2]
	var spell_counters_slots : Array[Label] = [$RigidUI/SpellEffectCounter1, $RigidUI/SpellEffectCounter2]
	for slot_idx in range(spell_effects_slots.size()):
		if entity.effects.size() - 1 < slot_idx:
			spell_effects_slots[slot_idx].texture = null
			spell_counters_slots[slot_idx].text = ""
			continue

		var spell_texture = load(entity.effects[slot_idx].icon_path)  #TEMP spell icon path
		spell_effects_slots[slot_idx].texture = spell_texture
		spell_counters_slots[slot_idx].text = str(entity.effects[slot_idx].duration_counter)



func set_selected(is_selected : bool):
	var c = Color.RED if is_selected else Color.WHITE
	$sprite_unit.modulate = c

#endregion UI
