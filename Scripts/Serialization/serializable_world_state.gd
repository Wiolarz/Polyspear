extends Resource
class_name SerializableWorldState

class PlayerState extends Resource:
	@export var goods : Array[int]
	@export var dead_heroes : Array[String] # TODO better handle heroes
											# for example saving level after
											# resurrection
	@export var capital_city : Vector2i

@export var unit_hexes : Dictionary
@export var place_hexes : Dictionary
@export var current_player : int = 0
@export var players : Array[PlayerState]


func valid() -> bool:
	var player_number = players.size()
	return player_number > 0 and current_player in range(player_number)

static func get_network_serialized(world_state : SerializableWorldState) \
		-> PackedByteArray:
	if not world_state:
		return PackedByteArray()
	var dict : Dictionary = {
		"units": world_state.unit_hexes,
		"places": world_state.place_hexes,
		"goods": world_state.goods,
		"dead_heroes": world_state.dead_heroes,
		"current_player": world_state.current_player,
		"capital_cities": world_state.capital_cities,
		"outpost_buildings": world_state.outpost_buildings,
		"outposts": world_state.outposts,
	}
	return var_to_bytes(dict)


static func from_network_serialized(ser : PackedByteArray):
	var dict = bytes_to_var(ser)
	var sws := SerializableWorldState.new()
	sws.unit_hexes = dict["units"]
	sws.place_hexes = dict["places"]
	sws.goods.resize(dict["goods"].size())
	# all these loops are here because i could not just assign these arrays :c
	for i in sws.goods.size():
		sws.goods[i] = dict["goods"][i]
	sws.dead_heroes.resize(dict["dead_heroes"].size())
	for i in sws.dead_heroes.size():
		sws.dead_heroes[i] = dict["dead_heroes"][i]
	sws.current_player = dict["current_player"]
	sws.capital_cities.resize(dict["capital_cities"].size())
	for i in sws.capital_cities.size():
		sws.capital_cities[i] = dict["capital_cities"][i]
	sws.outposts.resize(dict["outposts"].size())
	for i in sws.outposts.size():
		sws.outposts[i] = dict["outposts"][i]
	sws.outpost_buildings.resize(dict["outpost_buildings"].size())
	for i in sws.outpost_buildings.size():
		sws.outpost_buildings[i] = dict["outpost_buildings"][i]
	return sws
