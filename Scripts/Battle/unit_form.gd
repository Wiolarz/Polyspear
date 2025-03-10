class_name UnitForm
extends Node2D

## emitted when anim ends (move, turn, die)
signal anim_end()

const SIDE_NAMES = ["FrontSymbol", "FrontRightSymbol", "BackRightSymbol", "BackSymbol", "BackLeftSymbol", "FrontLeftSymbol"]
const selection_mark_scene = preload("res://Scenes/Form/SelectionMark.tscn")

@onready var sprite_border := $sprite_border

var entity : Unit
var _symbols_flipped : bool = true  # flag used for unit rotation

## these variables are needed for visual effects -- hex border needs
## them both to refresh its hightlight level
var _selected : bool = false
var _hovered : bool = false


func _process(_delta):
	if entity:
		$Symbols.modulate = Color.RED if entity.is_on_swamp else Color.WHITE

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
	result.rotation_degrees = new_unit.unit_rotation * 60
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
		_apply_symbol_activation_anim(side, template.symbols[side])
	
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

## Half-brained knock-off of _apply_symbol_sprite() to add the animation to the animated sprite of SymbolForm 
func _apply_symbol_activation_anim(side : int, symbol : DataSymbol) -> void:
	var symbol_animation : SymbolAnimation = symbol.symbol_animation
	var animated_sprite_path : String = "Symbols/%s/SymbolForm/ActivationAnim" % [SIDE_NAMES[side]]
	var symbol_anim_sprite = get_node(animated_sprite_path)
	if not symbol_animation:
		return #Animation does not exists for given symbol
		
	symbol_anim_sprite.sprite_frames = symbol.symbol_animation
	symbol_anim_sprite.scale = symbol_animation.scale
	symbol_anim_sprite.position = symbol_animation.offset


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

	$sprite_border.material.set_shader_parameter("modulate_color", \
		color.color)


func _apply_level_number(level : int) -> void:
	const roman_numbers = ["0", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	if level > 10 or level < 0:
		assert(false, "Design wise higher level units don't make sense")
		level = 1
	$RigidUI/UnitLevel.text = roman_numbers[level]

#endregion Init

#region Animations

func anim_move():
	var target = BM.get_tile_global_position(entity.coord)
	ANIM.main_tween().tween_property(self, "position", target, CFG.anim_move_duration)

func anim_turn():
	var time = CFG.anim_turn_duration
	var angle_rel = angle_difference(rotation, deg_to_rad(entity.unit_rotation * 60))
	ANIM.main_tween().tween_property(self, "rotation", angle_rel, time).as_relative()
	ANIM.main_tween().parallel().tween_property($sprite_unit, "rotation", -angle_rel, time).as_relative()
	ANIM.main_tween().parallel().tween_property($RigidUI, "rotation", -angle_rel, time).as_relative()
	_rotation_symbol_flip()
	_flip_unit_sprite()

func anim_die():
	ANIM.main_tween().tween_property(self, "scale", Vector2.ZERO, CFG.anim_death_duration)
	ANIM.main_tween().tween_callback(queue_free)

func anim_symbol(side : int, animation_type : int, target_coord: Vector2i = Vector2i(0,0)):
	var side_local : int = GenericHexGrid.rotate_clockwise( \
			side as GenericHexGrid.GridDirections, -entity.unit_rotation)
	var symbol = get_node("Symbols/%s/SymbolForm" % SIDE_NAMES[side_local])
	var symbol_sprite = symbol.get_node("Sprite2D")
	var symbol_activation_anim = symbol.get_node("ActivationAnim")
	var animation_frames: SymbolAnimation = symbol_activation_anim.sprite_frames
	# I honestly don't know what "playing_speed" means in this context
	var get_absolute_frame_duration = func get_absolute_frame_duration(animation : StringName, frames : SymbolAnimation = animation_frames) -> float:
		return frames.get_frame_duration(animation, 0) / frames.get_animation_speed(animation) #* abs(playing_speed)
	var absolute_frame_duration = get_absolute_frame_duration.call("default")
	var time_to_hit: float = animation_frames.hit_on_frame * absolute_frame_duration
	# makes the death animation wait for the moment of impact (but makes multihits look way less cool)
	# could be fixed by somehow detaching death animation from main tween
	var delay_death_animation: Callable = ANIM.main_tween().tween_interval
	
	var subtween = ANIM.subtween()
	var hex_border_animation = func hex_border_animation():
		subtween.tween_property(symbol_sprite, "scale", CFG.anim_symbol_activation_scale, 0.0)
		subtween.tween_property(symbol_sprite, "scale", Vector2(1.0, 1.0), CFG.anim_symbol_activation_duration)
	# Type-specific animation
	match animation_type:
		CFG.SymbolAnimationType.MELEE_ATTACK:
			subtween.tween_callback(symbol_activation_anim.play.bind("default"))
			hex_border_animation.call()
			delay_death_animation.call(time_to_hit)
		CFG.SymbolAnimationType.COUNTER_ATTACK:
			subtween.tween_callback(symbol_activation_anim.play.bind("default"))
			hex_border_animation.call()
			delay_death_animation.call(time_to_hit)
		CFG.SymbolAnimationType.TELEPORTING_PROJECTILE:
			subtween.tween_callback(symbol_activation_anim.play.bind("default"))
			hex_border_animation.call()
			var target_tile : TileForm = BM.get_tile_form(target_coord)
			print(target_coord)
			var projectile_animation_frames : SymbolAnimation = animation_frames.projectile_animation_frames
			# Create a temporary animated sprite for projectile
			#TODO the rotations are fucked
			var projectile_animated_sprite : AnimatedSprite2D = AnimatedSprite2D.new()
			add_child(projectile_animated_sprite)
			#idk if that's how to properly make it render on top of units
			projectile_animated_sprite.z_index = 1
			projectile_animated_sprite.sprite_frames = projectile_animation_frames
			projectile_animated_sprite.scale = projectile_animation_frames.scale
			projectile_animated_sprite.reparent(target_tile)
			projectile_animated_sprite.position = projectile_animation_frames.offset
			projectile_animated_sprite.global_rotation = symbol.global_rotation
			# Animate the thing
			# First, wait for the moment the projectile should appear
			# TODO this isn't perfect, ideally the order of evens should be as follows:
			# The symbol animation plays, at time_to_teleport the projectile plays,
			# at projectile_time_to_hit the target dies, then the shooter continues movement
			# while an independent timer waits to kill the proj after it's entire animation plays
			# Currently, shooter waits for the entire animation of the projectile to finish
			# before moving, and the delay to kill the projectile is too long for some reason
			var projectile_absolute_frame_duration : float = get_absolute_frame_duration.call("default", projectile_animation_frames)
			var projectile_time_to_hit : float = projectile_animation_frames.hit_on_frame * projectile_absolute_frame_duration
			var time_to_teleport : float = animation_frames.teleport_at * absolute_frame_duration
			#subtween.tween_interval(time_to_teleport)
			delay_death_animation.call(time_to_teleport)
			# Play it's animation
			ANIM.main_tween().tween_callback(projectile_animated_sprite.play.bind("default"))
			# Wait for the projectile to land
			delay_death_animation.call(projectile_time_to_hit)
			# Give the child cancer
			#This delay is too long
			subtween.tween_interval(
				projectile_animation_frames.get_frame_count("default") * 
				projectile_absolute_frame_duration + time_to_teleport - projectile_time_to_hit
			)
			subtween.tween_callback(projectile_animated_sprite.queue_free)
		CFG.SymbolAnimationType.BLOCK:
			# Set the animated sprite to blocking
			symbol_activation_anim.position = animation_frames.blocking_offset
			symbol_activation_anim.scale = animation_frames.blocking_scale
			# Play the blocking animation
			subtween.tween_callback(symbol_activation_anim.play.bind("block"))
			# Wait for it to finish
			# TODO this delay is too short for some reason
			subtween.tween_interval(
				get_absolute_frame_duration.call("block") *
				 animation_frames.get_frame_count("block"))
			# temporary solution
			#subtween.tween_interval(1)
			# Return to default position
			var return_to_default_state = func return_to_default_state():
				if symbol_activation_anim != null:
					symbol_activation_anim.position = animation_frames.offset
					symbol_activation_anim.scale = animation_frames.scale
				else:
					printerr("ERROR, called block animation on freed unit: ", self)
			subtween.tween_callback(return_to_default_state)

func anim_magic():
	# TODO
	pass

#endregion Animations

func _rotation_symbol_flip():
	_symbols_flipped = true

	for dir in range(6):
		var symbol_sprite = $"Symbols".get_children()[dir].get_child(0).get_child(0)
		if symbol_sprite.texture == null:
			continue
		_flip_symbol_sprite(symbol_sprite, dir)

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
	_selected = is_selected
	_refresh_highlight()


func set_hovered(is_hovered : bool):
	_hovered = is_hovered
	_refresh_highlight()


## used after every set_hovered and set_selected to refresh level of highlight
func _refresh_highlight() -> void:
	var overall_shader_material := material as ShaderMaterial
	var border_shader_material := sprite_border.material as ShaderMaterial
	var overall_intensity = 0.25 if _hovered else 0.0
	var border_intensity = 0.0
	border_intensity = lerpf(border_intensity, 1.0, 0.25 if _hovered else 0.0)
	border_intensity = lerpf(border_intensity, 1.0, 0.45 if _selected else 0.0)
	var border_modulate = 0.8 if _selected else 0.0
	var border_contrast_boost = 1.25 if _selected else 0.0
	overall_shader_material.set_shader_parameter("highlight_intensity", \
		overall_intensity)
	border_shader_material.set_shader_parameter("highlight_intensity", \
		border_intensity)
	border_shader_material.set_shader_parameter("modulate_intensity", \
		border_modulate)
	border_shader_material.set_shader_parameter("contrast_boost", \
		border_contrast_boost)

	if _selected:
		if not get_node_or_null("SelectionMark"):
			var mark = selection_mark_scene.instantiate()
			add_child(mark)
			move_child(mark, $sprite_color.get_index() + 1)
			mark.name = "SelectionMark"
			mark.position = Vector2(0.0, 0.0)
			z_index = 2
	elif get_node_or_null("SelectionMark"):
		remove_child(get_node_or_null("SelectionMark"))
		z_index = 0


#endregion UI
