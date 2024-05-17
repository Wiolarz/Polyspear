class_name E
extends Object


## Symbols for units in battle, assigned to each side of a hex
enum Symbols
{
	EMPTY,
	SPEAR,
	SWORD,
	SHIELD,
	BOW,
	PUSH,
}

## used to specify direction on a hex grid
enum GridDirections
{
	LEFT,
	TOP_LEFT,
	TOP_RIGHT,
	RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
}

enum PlayerType
{
	OBSERVER,
	HUMAN,
	BOT,
}

enum CameraPosition {WORLD, BATTLE}

enum WorldMapTiles
{
	SENTINEL,

	# fundamental game logic
	EMPTY,
	WALL,

	# UI based menu interfaces
	CITY,
	PLACE,

	# undefined
	DEPOSIT,
}

const DIRECTION_FRONT = GridDirections.LEFT


static func rotate_clockwise(direction : GridDirections, sides : int) -> GridDirections:
	return (direction + sides) % 6 as GridDirections


static func opposite_direction(direction : GridDirections) -> GridDirections:
	return rotate_clockwise(direction, 3)


static func symbol_to_name(s : Symbols) -> String:
	return Symbols.keys()[s]


static func direction_to_name(d : GridDirections) -> String:
	return GridDirections.keys()[d]


static func player_type_to_name(pt : PlayerType) -> String:
	return PlayerType.keys()[pt].to_lower()


static func world_map_tile_to_name(wmt : WorldMapTiles) -> String:
	return WorldMapTiles.keys()[wmt].to_lower()


func _init():
	assert(false, "do not instantiate this class, it's static only")

