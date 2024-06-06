class_name Place
extends RefCounted # RefCounted is default

signal controller_changed()

var type : E.WorldMapTiles = E.WorldMapTiles.EMPTY
var controller : Player
var defender_army : Army
var battle_map : DataBattleMap
var coord : Vector2i


# TODO move to other file and rework Place
static func _inner_create_place(new_data_tile : DataTile) -> Place:
	match new_data_tile.type:
		# city:
		"elf_city", "orc_city":
			return City.new()

		# Resource Outposts
		"sawmill":
			return Outpost.new(Goods.new(1,0,0), new_data_tile.type, CFG.OUTPOST_WOOD_PATH)
		"iron_mine":
			return Outpost.new(Goods.new(0,1,0), new_data_tile.type, CFG.OUTPOST_IRON_PATH)
		"ruby_cave":
			return Outpost.new(Goods.new(0,0,1), new_data_tile.type, CFG.OUTPOST_RUBY_PATH)

		# resource hunt spots
		"wood_hunt":
			return HuntSpot.new(CFG.HUNT_WOOD_PATH, [Goods.new(3,0,0), Goods.new(6,0,0)])
		"iron_hunt":
			return HuntSpot.new(CFG.HUNT_IRON_PATH, [Goods.new(0,3,0), Goods.new(0,6,0)])
		"ruby_hunt":
			return HuntSpot.new(CFG.HUNT_RUBY_PATH, [Goods.new(0,0,3), Goods.new(0,0,6)])

		_:#"sentinel", "wall", "empty"
			return null


static func create_place(new_data_tile : DataTile, \
			new_coord : Vector2i) -> Place:
	var new_place = _inner_create_place(new_data_tile)
	if new_place:
		new_place.coord = new_coord

	return new_place


func on_game_started() -> void:
	pass


func interact(army : ArmyForm) -> void:
	print(army)


func on_end_of_turn() -> void:
	pass


func get_map_description() -> String:
	return ""

func change_controler(player : Player):
	controller = player
	controller_changed.emit()


static func get_network_serializable(place : Place) -> Dictionary:
	if not place:
		return {}
	var dict : Dictionary = {}
	place.to_specific_serializable(dict)
	dict["type"] = place.type
	dict["player"] = WM.get_player_index(place.controller)
	# defender army will be get from unit_grid

	# var script : String = get_script().resource_path.get_file()
	# dict["script"] = script
	return dict


## should be overridden by each place
## but also this is a temporary part of greater refactor which is needed for
## Place class
func to_specific_serializable(dict : Dictionary) -> void:
	dict["not implemented"] = true
