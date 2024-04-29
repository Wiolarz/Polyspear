# Singleton - CFG
extends Node

enum BotSpeed
{
	FREEZE = 0,
	NORMAL = 60,
	FAST = 1,
}
## dont set it lower than 2 * animation_speed_frames
## or ai will not wait for animations to finish
var bot_speed_frames : BotSpeed = BotSpeed.NORMAL

enum AnimationSpeed
{
	NORMAL = 20,
	INSTANT = 666,
}
## both rotation and move take this much time,
## so unit move takes between X and 2X
var animation_speed_frames : AnimationSpeed = AnimationSpeed.NORMAL


const BATTLE_MAPS_PATH = "res://Resources/Battle/Battle_Maps/"
const UNITS_PATH = "res://Resources/Battle/Units/"
const BATTLE_PRESETS_PATH = "res://Resources/Presets/Battle/"
const WORLD_MAPS_PATH = "res://Resources/World/World_maps/"
const SENTINEL_TILE_PATH = "res://Resources/World/World_tiles/sentinel.tres"
const BATTLE_MAP_TILES_PATH = "res://Resources/Battle/Battle_tiles/"
const WORLD_MAP_TILES_PATH = "res://Resources/World/World_tiles/"
const SYMBOLS_PATH = "res://Resources/Battle/Symbols/"

var FACTION_ELVES : DataFaction = load("res://Resources/Factions/elf.tres")
var FACTION_ORCS : DataFaction = load("res://Resources/Factions/orc.tres")

var FACTIONS_LIST : Array[DataFaction] = [
	FACTION_ELVES,
	FACTION_ORCS,
]

const UNIT_FORM_SCENE = preload("res://Scenes/Form/UnitForm.tscn")
var HEX_TILE_FORM_SCENE = load("res://Scenes/Form/TileForm.tscn")
const SUMMON_BUTTON_TEXTURE:Texture2D = preload("res://Art/battle_map/grass.png")

const DEFAULT_USER_NAMES : Array[String] = [
	"Zdzichu",
	"Mag",
	"Gołąb",
	"Polygończyk",
	"Przemek",
	"Czarodziej",
	"Student",
	"Stary",
	"Cebularz",
	"DJ Skwarka",
	"Książę żab Marcin",
	"Gracz Doty",
]

func get_random_username() -> String:
	return DEFAULT_USER_NAMES[randi() % DEFAULT_USER_NAMES.size()]

const DEFAULT_USER_NAME : String = "(( you ))"

const TEAM_COLORS : Array[Dictionary] = [
	{ "name": "red", "color": Color(1.0, 0.0, 0.0) },
	{ "name": "blue", "color": Color(0.0, 0.4, 1.0) },
	{ "name": "green", "color": Color(0.0, 0.9, 0.0) },
	{ "name": "yellow", "color": Color(0.9, 0.8, 0.0) },
	{ "name": "purple", "color": Color(0.9, 0.2, 0.85) },
	{ "name": "orange", "color": Color(0.9, 0.5, 0.0) },
]

const DEFAULT_TEAM_COLOR = Color(0.5, 0.5, 0.5, 1.0)

func get_team_color_at(index : int) -> Color:
	if not index in range(TEAM_COLORS.size()):
		return DEFAULT_TEAM_COLOR
	return TEAM_COLORS[index]["color"]

var DEFAULT_BATTLE_MAP : DataBattleMap = \
	load("res://Resources/Battle/Battle_Maps/basic5x5.tres")
const DEFAULT_ARMY_FORM = preload("res://Scenes/Form/ArmyForm.tscn")

func get_start_goods() -> Goods:
	return Goods.new(10,5,1)
