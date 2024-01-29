extends Node

class_name E

enum HexTileType {
	INVALID,
	SENTINEL,
	ATTACKER_SPAWN,
	DEFENDER_SPAWN,
	DEFAULT,

}



enum Player {
	INVALID,
	ATTACKER,
	DEFENDER,
}


enum Symbols {
	INVALID,
	SPEAR,
	SWORD,
	SHIELD,
	BOW,
	PUSH,
}


enum AutomaticTestsList {
	INVALID,
	EMPTY,
	BASIC_UNIT_SETUP,
}
