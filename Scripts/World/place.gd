class_name Place
extends Node

@export var type : E.WorldMapTiles = E.WorldMapTiles.EMPTY
@export var controller : Player
@export var defender_army : Army
@export var battle_map : BattleMap
@export var coord : Vector2i

func interact(army : ArmyOnWorldMap):
	print(army)

static func create_place(new_data_tile : DataTile) -> Place:
	
	match new_data_tile.type:
		"sawmill", "iron_mine", "ruby_cave":
			return Deposit.new()
		"elf_city", "orc_city":
			return City.new()
		_:#"sentinel", "wall", "empty"
			return null
		