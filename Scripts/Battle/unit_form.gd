class_name UnitForm
extends Node2D

## emitted when anim ends (move, turn, die)
signal anim_end()

const SIDE_NAMES = ["FrontSymbol", "FrontRightSymbol", "BackRightSymbol", "BackSymbol", "BackLeftSymbol", "FrontLeftSymbol"]
const selection_mark_scene = preload("res://Scenes/Form/SelectionMark.tscn")

@onready var sprite_border := $sprite_border

var entity : Unit

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

	result.ready.connect(result.apply_graphics.bind(new_unit.template, color))

	result.global_position = BM.get_tile_global_position(new_unit.coord)
	result.rotation_degrees = new_unit.unit_rotation * 60
	result.get_node("sprite_unit").rotation = -result.rotation
	result.get_node("RigidUI").rotation = -result.rotation
	return result


## HACK, this is for visuals only for summon UI
## no underlying Unit exists
static func create_for_summon_ui(template: DataUnit, color : DataPlayerColor) -> UnitForm:
	var result = CFG.UNIT_FORM_SCENE.instantiate()
	# defer apply_graphics to after the symbol forms are ready (they must be in order for this to work)
	result.ready.connect(result.apply_graphics.bind(template, color))
	return result


func apply_graphics(template : DataUnit, color : DataPlayerColor):
	var unit_texture = load(template.texture_path) as Texture2D
	_apply_unit_texture(unit_texture)
	_apply_color_texture(color)
	_apply_level_number(template.level)

	for side in range(0,6):
		var symbol_texture
		if entity:   # effects may change symbols during battle
			symbol_texture = entity.symbols[side].texture_path
		else:  # Placement screen
			symbol_texture = template.symbols[side].texture_path

		var data_symbol = template.symbols[side]
		var symbol = get_symbol(side)
		var unit_rotation = entity.unit_rotation if entity else 0
		var side_local = (unit_rotation + side) % 6

		symbol.apply_sprite(side_local, symbol_texture)
		symbol.apply_activation_anim(data_symbol)

	_flip_unit_sprite()
	$RigidUI/SpellEffect1.texture = null
	$RigidUI/SpellEffect2.texture = null
	$RigidUI/SpellEffectCounter1.text = ""
	$RigidUI/SpellEffectCounter2.text = ""
	$RigidUI/TerrainEffect.texture = null


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


func anim_symbol(side : int, animation_type : int, target_coord: Vector2i = Vector2i.ZERO):
	if target_coord == Vector2i.ZERO:
		target_coord = entity.coord + GenericHexGrid.DIRECTION_TO_OFFSET[side]

	var side_local : int = GenericHexGrid.rotate_clockwise(
		side,
		-entity.unit_rotation
	)

	var symbol : SymbolForm = get_symbol(side_local)

	var other_unit : UnitForm = BM.get_unit_form(target_coord)

	#TEMP fix to account for bows not shooting before the move, I'm still not sure how it works exactly
	if not other_unit:
		target_coord += GenericHexGrid.DIRECTION_TO_OFFSET[GenericHexGrid.opposite_direction(side)]

	var opposite_side_local : int = GenericHexGrid.rotate_clockwise(
		GenericHexGrid.opposite_direction(side),
		-other_unit.entity.unit_rotation
	)

	var other_symbol : SymbolForm = other_unit.get_symbol(opposite_side_local)

	# TODO animation delay makes the death animation wait for
	# the moment of impact (but makes multihits look way less cool)
	# could be fixed by somehow detaching death animation from main tween

	match animation_type:
		CFG.SymbolAnimationType.MELEE_ATTACK, CFG.SymbolAnimationType.COUNTER_ATTACK:
			symbol.anim_symbol_melee(animation_type)

		CFG.SymbolAnimationType.TELEPORTING_PROJECTILE:
			symbol.anim_symbol_teleporting_projectile(target_coord, side)

		CFG.SymbolAnimationType.BLOCK:
			var block_anim_duration : float = symbol.get_block_duration()

			var data_symbol : DataSymbol = \
				other_unit.entity.symbols[opposite_side_local]

			if data_symbol.does_it_shoot():
				other_symbol.anim_symbol_teleporting_projectile(
					entity.coord,
					GenericHexGrid.opposite_direction(side)
				)
			else:
				other_symbol.anim_symbol_melee(
					CFG.SymbolAnimationType.MELEE_ATTACK,
					block_anim_duration
				)

			symbol.anim_symbol_block()

		_:
			assert(false, "Unimplemented animation type")



func anim_magic():
	# TODO
	pass

#endregion Animations

func get_symbol(side_local : int) -> SymbolForm:
	return get_node("Symbols/%s/SymbolForm" % SIDE_NAMES[side_local])


func _rotation_symbol_flip():
	for dir in range(6):
		var abstract_rotation = (entity.unit_rotation + dir) % 6
		get_symbol(dir).flip_sprite(abstract_rotation)


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
		if not entity.effects[slot_idx].passive_effect:  # passive effect are pernament
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
