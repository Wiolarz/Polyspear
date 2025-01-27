class_name BattlePainter
extends Node2D


var new_arrow : ChessArrow 
var arrows_to_draw : Array[ChessArrow] = []  # Array[Array[Vector2]]

func _draw():
	var _line_width : float = 80.0

	for arrow : ChessArrow in arrows_to_draw:
		var color : Color = _get_color_from_index(arrow.color_idx)
		draw_polyline(arrow.draw_path, color, _line_width)


func erase():
	arrows_to_draw = []
	Helpers.remove_all_children(self)
	queue_redraw()


func _get_color_from_index(color_idx : int) -> Color:
	var color : Color = Color.WHITE_SMOKE  # default 0 value
	match color_idx:
		1:
			color = Color.LIGHT_GREEN
		2:
			color = Color.INDIAN_RED
		3:
			color = Color.BLUE
		4:
			color = Color.ORANGE
		5:
			color = Color.BLACK
		6:
			color = Color.PINK
		7:
			color = Color.PURPLE
	return color


#region Planning (Chess arrows)

## Draws a single pointer on a tile, those are cleared by any normal (left click) input
func planning_input(tile_coord : Vector2i, is_it_pressed : bool) -> void:
	if is_it_pressed:
		if not new_arrow:
			var arrow_color_idx = 0
			if Input.is_key_pressed(KEY_CTRL):
				arrow_color_idx += 1
			if Input.is_key_pressed(KEY_ALT):
				arrow_color_idx += 2
			if Input.is_key_pressed(KEY_SHIFT):
				arrow_color_idx += 4
			

			new_arrow = ChessArrow.creat_chess_arrow(arrow_color_idx, tile_coord)
			return
		
		if tile_coord not in new_arrow.hex_path:
			new_arrow.add_hex(tile_coord)
		return
	
	
	# mouse press is released, draw final
	
	if not new_arrow:
		# edge case when godot input is strange and registers mouse unlicking from object which it didnt click
		return 

	if new_arrow.hex_path.size() == 1:  # a single pointer
		var pointer = CFG.PLAN_POINTER_SCENE.instantiate()
		pointer.modulate = _get_color_from_index(new_arrow.color_idx)
		pointer.position = new_arrow.draw_path[0]
		add_child(pointer)
	else:
		arrows_to_draw.append(new_arrow)
		var arrow_end = CFG.PLAN_ARROW_END_SCENE.instantiate()
		arrow_end.modulate = _get_color_from_index(new_arrow.color_idx)
		arrow_end.position = new_arrow.draw_path[-1]
		var offset = new_arrow.hex_path[-2] - new_arrow.hex_path[-1]  # angle between last two coords
		var rotation_value = GenericHexGrid.DIRECTION_TO_OFFSET.find(offset) * PI / 3
		arrow_end.rotation = rotation_value
		#print(offset)
		add_child(arrow_end)
		queue_redraw()

	new_arrow = null  # reset arrow path


class ChessArrow:
	var color_idx : int = 0
	var hex_path : Array[Vector2i] = []
	var draw_path : Array[Vector2] = []
	static func creat_chess_arrow(color_idx : int, first_coord : Vector2) -> ChessArrow:
		var new_arrow := ChessArrow.new()
		new_arrow.color_idx = color_idx
		new_arrow.hex_path = [first_coord]
		new_arrow.draw_path = [BM.to_position(first_coord)]
		return new_arrow

	func add_hex(coord : Vector2i) -> void:
		hex_path.append(coord)
		draw_path.append(BM.to_position(coord))


#endregion Planning (Chess arrows)
