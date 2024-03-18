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

	# logika gry bazowa
	EMPTY,
	WALL,
	
	# menusy
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

enum HexTileType 
{
	SENTINEL,
	ATTACKER_SPAWN,
	DEFENDER_SPAWN,
	DEFAULT,
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


