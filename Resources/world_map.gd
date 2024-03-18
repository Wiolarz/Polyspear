class_name WorldMap

extends GridBoard

"""
Placeholder variables.

Complete world map data:
	1 Placement of every tile type
	2 Info about assignment of every city
"""




func apply_data():

	W_GRID.map_information = self


	W_GRID.max_player_number = max_player_number
	W_GRID.grid_width = grid_width
	W_GRID.grid_height = grid_height