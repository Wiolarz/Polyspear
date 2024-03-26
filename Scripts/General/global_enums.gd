class_name E

extends Node

#region General

enum player_type
{
	OBSERVER,
	HUMAN,
	BOT,
}




#region World

enum WorldMapTiles
{
	SENTINEL,

	# fundemantal game logic
	EMPTY,
	WALL,
	
	# UI based menu interfaces
	CITY,
	PLACE,
}

#endregion


#region Battle

enum MapShape
{
	CLASSIC,
	SHIFTED,
}

enum Symbols
{
	EMPTY,
	SPEAR,
	SWORD,
	SHIELD,
	BOW,
	PUSH,
}

#endregion


