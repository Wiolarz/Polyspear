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

## battle map is placed this far to the right after world map bounds
const MAPS_OFFSET_X = 7000

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

## URL for trying to determine external IP
## must support plain GET request
## that returns address as a single text line in the response body
const FETCH_EXTERNAL_IP_GET_URL = "https://api.ipify.org"

func get_start_goods() -> Goods:
	return Goods.new(10,5,1)

#region Neutral Units armies

const HUNT_WOOD_PATH : String = "res://Resources/Presets/Army/hunt_wood/"
const HUNT_IRON_PATH : String = "res://Resources/Presets/Army/hunt_iron/"
const HUNT_RUBY_PATH : String = "res://Resources/Presets/Army/hunt_ruby/"

#const HUNT_PATHS : Array[String] = [HUNT_WOOD_PATH, HUNT_IRON_PATH, HUNT_RUBY_PATH]

#endregion

#region World Map properties

const WORLD_MOVEABLE_TILES = [
	"empty",
	"iron_mine",
	"sawmill",
	"ruby_cave",
	"wood_hunt",
	"iron_hunt",
	"ruby_hunt",
]

var DEFAULT_MODE_IS_BATTLE : bool : 
	get: return player_options.use_default_battle
var AUTO_START_GAME : bool : 
	get: return player_options.autostart_map

#endregion

const PLAYER_OPTIONS_PATH = "user://player_options.tres"
var player_options : PlayerOptions

func _init():
	player_options = load(PLAYER_OPTIONS_PATH)
	if not player_options:
		player_options = PlayerOptions.new()

func save_player_options():
	ResourceSaver.save(player_options, PLAYER_OPTIONS_PATH)
