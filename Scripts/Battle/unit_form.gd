class_name UnitForm
extends Node2D

## emitted when anim ends (move, turn, die)
signal anim_end()

const SIDE_NAMES = ["FrontSymbol", "FrontRightSymbol", "BackRightSymbol", "BackSymbol", "BackLeftSymbol", "FrontLeftSymbol"]
const selection_mark_scene = preload("res://Scenes/Form/SelectionMark.tscn")

@onready var sprite_color := $sprite_color

var entity : Unit
var _symbols_flipped : bool = true  # flag used for unit rotation


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

func anim_symbol(side: int):
	var side_local : int = GenericHexGrid.rotate_clockwise( \
			side as GenericHexGrid.GridDirections, -entity.unit_rotation)
	var symbol = get_node("Symbols/%s/SymbolForm" % SIDE_NAMES[side_local])
	var tween = ANIM.subtween()
	tween.tween_property(symbol, "scale", CFG.anim_symbol_activation_scale, 0.0)
	tween.tween_property(symbol, "scale", Vector2(1.0, 1.0), CFG.anim_symbol_activation_duration)

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
	if is_selected and not get_node_or_null("SelectionMark"):
		var mark = selection_mark_scene.instantiate()
		add_child(mark)
		mark.name = "SelectionMark"
		mark.position = Vector2(0.0, 0.0)
		z_index = 2
	else:
		remove_child(get_node_or_null("SelectionMark"))
		z_index = 0


func set_hovered(is_hovered : bool):
	var shader_material := material as ShaderMaterial
	var intensity = 0.3 if is_hovered else 0.0
	shader_material.set_shader_parameter("highlight_intensity", intensity)

#endregion UI
