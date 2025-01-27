class_name BattlePainter
extends Node2D

#region Planning (Chess arrows)

var new_arrow_path : Array[Vector2i] = []
var arrows_to_draw : Array = []  # Array[Array[Vector2]]


func erase():
	arrows_to_draw = []
	Helpers.remove_all_children(self)
	queue_redraw()
	


## Draws a single pointer on a tile, those are cleared by any normal (left click) input
## TODO add arrows 
func planning_input(tile_coord : Vector2i, is_it_pressed : bool) -> void:
	var color : Color = Color.WHITE_SMOKE

	if not is_it_pressed:  # mouse press is released, draw final
		if new_arrow_path.size() == 0:  # safety meassure
			# player started drawing outside of the map,
			# on a first tick of entering a hex tile he unclicked
			return
		elif new_arrow_path.size() == 1:  # a single pointer
			var pointer = CFG.PLAN_POINTER_SCENE.instantiate()
			pointer.modulate = color
			pointer.position = BM.to_position(tile_coord)
			add_child(pointer)
		else:
			
			var arrow_line_positions : Array[Vector2] = []
			for hex in new_arrow_path:
				arrow_line_positions.append(BM.to_position(hex))
			arrows_to_draw.append(arrow_line_positions)

			var arrow_end = CFG.PLAN_ARROW_END_SCENE.instantiate()
			arrow_end.modulate = color
			arrow_end.position = BM.to_position(tile_coord)
			var offset = new_arrow_path[-2] - new_arrow_path[-1]  # angle between last two coords
			var rotation_value = GenericHexGrid.DIRECTION_TO_OFFSET.find(offset) * PI/3
			arrow_end.rotation = rotation_value
			add_child(arrow_end)

		print(new_arrow_path)
		queue_redraw()
		new_arrow_path = []  # reset arrow path
		return

	if tile_coord not in new_arrow_path:
		new_arrow_path.append(tile_coord)




#endregion Planning (Chess arrows)


func _draw():

	var color : Color = Color.WHITE_SMOKE
	
	var _line_width : float = 80.0

	for arrow in arrows_to_draw:
		if arrow.size() >= 2:
			draw_polyline(arrow, color, _line_width)
	