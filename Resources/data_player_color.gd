class_name DataPlayerColor

extends Resource

@export var name : String = "neutral"
@export var color : Color = Color(0.5, 0.5, 0.5)
@export var color_secondary : Color = Color(0.2, 0.2, 0.2)
@export var hexagon_texture : String = "gray_color"

const default_secondary_mix : Color = Color(0.2, 0.2, 0.2)


static func create(name_ : String, color_ : Color) -> DataPlayerColor:
	var data_player_color := DataPlayerColor.new()
	data_player_color.name = name_
	data_player_color.color = color_
	data_player_color.color_secondary = _create_default_secondary(color_)
	data_player_color.hexagon_texture = "%s_color" % name_
	return data_player_color


static func create_with_texture(name_ : String, color_ : Color, \
			texture_ : String) -> DataPlayerColor:
	var data_player_color := DataPlayerColor.new()
	data_player_color.name = name_
	data_player_color.color = color_
	data_player_color.color_secondary = _create_default_secondary(color_)
	data_player_color.hexagon_texture = texture_
	return data_player_color


# probably TEMP
static func _create_default_secondary(primary : Color) -> Color:
	const secondary_color_shift_power := 0.81
	return lerp(primary, default_secondary_mix, secondary_color_shift_power)

