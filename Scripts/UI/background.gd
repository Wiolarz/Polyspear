# Singleton - BG
extends CanvasLayer

const COLOR_DEFAULT = Color(0.32941176470588, 0.0, 1.0, 1.0)
const COLOR_SECONDARY_DEFAULT = Color(0.073, 0.0, 0.47, 1.0)

var _style_box = preload("res://Art/UI/marble_box.tres")
var _material : ShaderMaterial
var _actual_background : Panel

var _color1 : Color:
	set(new):
		if new is Color:
			_color1 = new
		else:
			_color1 = CFG.NEUTRAL_COLOR.color
		_material.set_shader_parameter("color1", _color1)

var _color2 : Color:
	set(new):
		if new is Color:
			_color2 = new
		else:
			_color2 = CFG.NEUTRAL_COLOR.color_secondary
		_material.set_shader_parameter("color2", _color2)


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


func set_player_colors(data : DataPlayerColor, tween: Tween = null) -> void:
	var primary := CFG.NEUTRAL_COLOR.color
	var secondary := CFG.NEUTRAL_COLOR.color_secondary
	
	if CFG.player_options.background_color_follows_players:
		primary = lerp(data.color, Color.BLACK, 0.1)
		secondary = data.color_secondary
		
	if tween:
		tween.tween_property(self, "_color1", primary, 0.5).set_trans(Tween.TRANS_LINEAR)
		tween.parallel().tween_property(self, "_color2", secondary, 0.5).set_trans(Tween.TRANS_LINEAR)
	else:
		_color1 = primary
		_color2 = secondary


func set_default_colors() -> void:
	# cannot set _colorX to null directly
	_color1 = COLOR_DEFAULT
	_color2 = COLOR_SECONDARY_DEFAULT
