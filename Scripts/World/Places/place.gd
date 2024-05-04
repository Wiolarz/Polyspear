class_name Place
extends Node


@export var type : E.WorldMapTiles = E.WorldMapTiles.EMPTY
@export var controller : Player
@export var defender_army : Army
@export var battle_map : DataBattleMap
@export var coord : Vector2i


static func _inner_create_place(new_data_tile : DataTile, coord : Vector2i) -> Place:
	match new_data_tile.type:
		# Resource Outposts
		"sawmill":
			return Deposit.new(Goods.new(5,0,0), Goods.new(1,0,0))
		"iron_mine":
			return Deposit.new(Goods.new(0,5,0), Goods.new(0,1,0))
		"ruby_cave":
			return Deposit.new(Goods.new(0,0,5), Goods.new(0,0,1))
		
		# city:
		"elf_city", "orc_city":
			return City.new()
		"wood_hunt":
			return HuntSpot.new(coord, CFG.HUNT_WOOD_PATH, [Goods.new(3,0,0), Goods.new(6,0,0)])
		"iron_hunt":
			return HuntSpot.new(coord, CFG.HUNT_IRON_PATH, [Goods.new(0,3,0), Goods.new(0,6,0)])
		"ruby_hunt":
			return HuntSpot.new(coord, CFG.HUNT_RUBY_PATH, [Goods.new(0,0,3), Goods.new(0,0,6)])

		_:#"sentinel", "wall", "empty"
			return null


static func create_place(new_data_tile : DataTile, \
		new_coord : Vector2i) -> Place:
	var new_place = _inner_create_place(new_data_tile, new_coord)
	if new_place != null:
		new_place.coord = new_coord

	return new_place


func interact(army : ArmyForm) -> void:
	print(army)


func on_end_of_turn() -> void:
	pass


func get_map_description() -> String:
	return ""
