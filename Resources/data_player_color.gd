class_name DataPlayerColor

extends Resource

@export var name : String = "neutral"
@export var color : Color = Color(0.5, 0.5, 0.5)
@export var hexagon_texture : String = "gray_color"


static func create(name_ : String, color_ : Color) -> DataPlayerColor:
	var data_player_color := DataPlayerColor.new()
	data_player_color.name = name_
	data_player_color.color = color_
	data_player_color.hexagon_texture = "%s_color" % name_
	return data_player_color


static func create_with_texture(name_ : String, color_ : Color, \
			texture_ : String) -> DataPlayerColor:
	var data_player_color := DataPlayerColor.new()
	data_player_color.name = name_
	data_player_color.color = color_
	data_player_color.hexagon_texture = texture_
	return data_player_color
