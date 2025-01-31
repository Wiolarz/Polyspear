class_name Background
extends CanvasLayer

var _style_box = preload("res://Art/UI/marble_box.tres")
var _material : ShaderMaterial
var _actual_background : Panel


func _ready() -> void:
	set_layer(-1)
	_material = ShaderMaterial.new()
	_material.shader = load("res://Art/UI/background.gdshader")

	_actual_background = Panel.new()
	_actual_background.add_theme_stylebox_override("panel", _style_box)
	_actual_background.set_anchors_and_offsets_preset( \
		Control.LayoutPreset.PRESET_FULL_RECT)
	_actual_background.material = _material
	_actual_background.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	add_child(_actual_background)


func set_player_colors(data : DataPlayerColor) -> void:
	if CFG.player_options.background_color_follows_players:
		set_colors(lerp(data.color, Color.BLACK, 0.1), data.color_secondary)
	else:
		set_colors(CFG.NEUTRAL_COLOR.color, CFG.NEUTRAL_COLOR.color_secondary)


func set_colors(color1 : Color, color2 : Color) -> void:
	_material.set_shader_parameter("color1", color1)
	_material.set_shader_parameter("color2", color2)


func set_default_colors() -> void:
	_material.set_shader_parameter("color1", null)
	_material.set_shader_parameter("color2", null)
