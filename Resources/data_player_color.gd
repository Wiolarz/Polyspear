class_name DataPlayerColor

extends Resource

@export var name : String = "neutral"
@export var color : Color = Color(0.5, 0.5, 0.5)
@export var hexagon_texture : String = "gray_color"


static func create(name : String, color : Color) -> DataPlayerColor:
	var data_player_color := DataPlayerColor.new()
	data_player_color.name = name
	data_player_color.color = color
	data_player_color.hexagon_texture = "%s_color" % name
	return data_player_color


static func create_with_texture(name : String, color : Color, tex : String) \
		-> DataPlayerColor:
	var data_player_color := DataPlayerColor.new()
	data_player_color.name = name
	data_player_color.color = color
	data_player_color.hexagon_texture = tex
	return data_player_color
