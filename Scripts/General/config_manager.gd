# Singleton - CFG
extends Node


## battle map is placed this far to the right after world map bounds
const MAPS_OFFSET_X = 7000 + 30000 # TEMP increase to include fake snetinel border

const BATTLE_BORDER_WIDTH = 15
const BATTLE_BORDER_HEIGHT = 8


#region Animations

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

var anim_default_ease := Tween.EASE_OUT
var anim_default_trans := Tween.TRANS_CUBIC
var anim_move_duration := 0.3
var anim_turn_duration := 0.3
var anim_death_duration := 0.3
var anim_symbol_fade_in_out_time := 0.1

## TODO Old system of upscaling animation could be used for symbols that don’t have proper animation
var anim_symbol_activation_scale := Vector2(2.0, 2.0)
var anim_symbol_activation_duration := 0.8


# STUB, TBH not used yet really
enum GuiAnimationMode
{
	NONE,
	NON_DISTRACTION,
	FULL,
	MAX_ = FULL + 1,
}

## To pass as argument for symbol animations to use special behavior
enum SymbolAnimationType
{
	DEFAULT,
	MELEE_ATTACK,
	BLOCK,
	TELEPORTING_PROJECTILE,
	COUNTER_ATTACK
}

#endregion Animations


#region Paths

## Folder Paths
const BATTLE_MAPS_PATH = "res://Resources/Battle/Battle_Maps/"
const UNITS_PATH = "res://Resources/Battle/Units/"
const HEROES_PATH = "res://Resources/Battle/Heroes/"
const BUILDINGS_PATH = "res://Resources/Races/Buildings/"
const BATTLE_PRESETS_PATH = "res://Resources/Presets/Battle/"
const WORLD_MAPS_PATH = "res://Resources/World/World_maps/"
const SENTINEL_TILE_PATH = "res://Resources/World/World_tiles/sentinel.tres"
const BATTLE_MAP_TILES_PATH = "res://Resources/Battle/Battle_tiles/"
const WORLD_MAP_TILES_PATH = "res://Resources/World/World_tiles/"
const SYMBOLS_PATH = "res://Resources/Battle/Symbols/"
const SPELLS_PATH = "res://Resources/Battle/Battle_Spells/"
const BATTLE_BOTS_PATH = "res://Resources/Battle/Bots"

const EMPTY_SYMBOL_PATH = "res://Resources/Battle/Symbols/empty.tres"
@onready var EMPTY_SYMBOL : DataSymbol = load(EMPTY_SYMBOL_PATH)


# Icons
const ROCK_ICON_PATH = "res://Art/battle_map/rock.png"
const SWAMP_ICON_PATH = "res://Art/battle_map/swamp.png"
const MANA_ICON_PATH = "res://Art/battle_map/mana_well.png"

const PLAYER_COLORS_PATH = "res://Art/player_colors/"

# System folders
const REPLAY_DIRECTORY = "user://replays/"
const PLAYER_OPTIONS_PATH = "user://player_options.tres"


const TUTORIAL_CONTENT_PATH = "res://Resources/Campaign/Tutorial/"
const PUZZLE_CONTENT_PATH = "res://Resources/Campaign/Puzzle/"
const CAMPAIGN_BATTLES_ELVES_PATH = "res://Resources/Campaign/Elves/"


var RACE_ELVES : DataRace = load("res://Resources/Races/elf.tres")
var RACE_ORCS : DataRace = load("res://Resources/Races/orc.tres")
var RACES_LIST : Array[DataRace] = [
	RACE_ELVES,
	RACE_ORCS,
]


const UNIT_FORM_SCENE = preload("res://Scenes/Form/UnitForm.tscn")
var HEX_TILE_FORM_SCENE := load("res://Scenes/Form/TileForm.tscn") as PackedScene
const SUMMON_BUTTON_TEXTURE:Texture2D = preload("res://Art/battle_map/grass.png")

const DEFAULT_ARMY_FORM = preload("res://Scenes/Form/ArmyForm.tscn")

const MOVE_HIGHLIGHT_SCENE = preload("res://Scenes/UI/Battle/BattleMoveHighlight.tscn")
const PLAN_POINTER_SCENE = preload("res://Scenes/UI/Battle/BattlePlanPointer.tscn")
const PLAN_ARROW_END_SCENE = preload("res://Scenes/UI/Battle/BattlePlanArrowEnd.tscn")

# Neutral Units armies
const HUNT_WOOD_PATH : String = "res://Resources/Presets/Army/hunt_wood/"
const HUNT_IRON_PATH : String = "res://Resources/Presets/Army/hunt_iron/"
const HUNT_RUBY_PATH : String = "res://Resources/Presets/Army/hunt_ruby/"

const OUTPOST_WOOD_PATH : String = "res://Resources/Presets/Army/outpost_defenders/outpost_wood_defender.tres"
const OUTPOST_IRON_PATH : String = "res://Resources/Presets/Army/outpost_defenders/outpost_iron_defender.tres"
const OUTPOST_RUBY_PATH : String = "res://Resources/Presets/Army/outpost_defenders/outpost_ruby_defender.tres"

#const HUNT_PATHS : Array[String] = [HUNT_WOOD_PATH, HUNT_IRON_PATH, HUNT_RUBY_PATH]


## Heroes Passive Effects

## magic weapon - all weapons have an attack power of 4, but each kills lowers that value by 1 to a min. of 1
const tier_2_passive_1 : String = "res://Resources/Battle/Battle_Spells/Heroes_Passive_Effects/magic_weapon.tres"

## used for passive that replaces all empty symbols with weak weapons
const weak_weapon : String = "res://Resources/Battle/Symbols/club.tres"

#endregion Paths


#region Colors

var TEAM_COLORS : Array[DataPlayerColor] = [
	DataPlayerColor.create("blue", Color(0.0, 0.4, 1.0)),
	DataPlayerColor.create("orange", Color(0.9, 0.5, 0.0)),
	DataPlayerColor.create("red", Color(1.0, 0.0, 0.0)),
	DataPlayerColor.create("purple", Color(0.9, 0.2, 0.85)),
	DataPlayerColor.create("green", Color(0.0, 0.9, 0.0)),
	DataPlayerColor.create("yellow", Color(0.9, 0.8, 0.0)),
]

var NEUTRAL_COLOR := \
	DataPlayerColor.create_with_texture("neutral", Color(0.5, 0.5, 0.5), \
		"gray_color")

var DEFAULT_TEAM_COLOR := \
	DataPlayerColor.create("gray", Color(0.5, 0.5, 0.5))


func get_team_color_at(index : int) -> DataPlayerColor:
	if not index in range(TEAM_COLORS.size()):
		return DEFAULT_TEAM_COLOR
	return TEAM_COLORS[index]

#endregion Colors


#region Battle maps

var DEFAULT_BATTLE_MAP : DataBattleMap = \
	load("res://Resources/Battle/Battle_Maps/basic5x5.tres")

var BIGGER_BATTLE_MAP : DataBattleMap = \
	load("res://Resources/Battle/Battle_Maps/8x7duel_10maxUnits.tres")

#endregion Battle maps


#region Multiplayer

## URL for trying to determine external IP
## must support plain GET request
## that returns address as a single text line in the response body
const FETCH_EXTERNAL_IP_GET_URL = "https://api.ipify.org"

const POLYAPI_BASE_URL = "https://polyserver.onrender.com/"
# for tests:
# const POLYAPI_BASE_URL = "http://localhost:3001/"

#endregion Multiplayer


#region Battle Map properties

#TEMP variables until better mana equation is implemented
const BIG_CYCLONE_COUNTER_VALUE = 30
const SMALL_CYCLONE_COUNTER_VALUE = 15
const CYCLONE_MANA_THRESHOLD = 3

#endregion Battle Map properties


#region World Map properties

const HERO_LEVEL_CAP = 7

func get_start_goods() -> Goods:
	return Goods.new(10,5,3)

const WORLD_MOVABLE_TILES = [
	"EMPTY",
	"iron_mine",
	"sawmill",
	"ruby_cave",
	"wood_hunt",
	"iron_hunt",
	"ruby_hunt",
	"elf_city",
	"orc_city",
]

#endregion World Map properties


#region Chess clock

const CHESS_CLOCK_BATTLE_TIME_PER_PLAYER_MS = 3 * 60 * 1000
const CHESS_CLOCK_BATTLE_TURN_INCREMENT_MS = 2 * 1000

#endregion Chess clock


#region Debugging & tests

# Also documented in Documentation/libspear.md
## Checks each time a move is done whether results of a move replicated in BattleManagerFast match results in a regular BM
var debug_check_bmfast_integrity : bool :
	get: return player_options.bmfast_integrity_checks
## Enables additional BattleManagerFast internal integrity checks, which may slightly reduce performance
var debug_check_bmfast_internals : bool :
	get: return player_options.bmfast_integrity_checks
## When greater than zero, saves replays from playouts where errors were detected
var debug_mcts_max_saved_fail_replays := 16
## When true, immediately save replays from BattleManagerFast mismatches with an appropriate name with a suffix "BMFast Mismatch"
var debug_save_failed_bmfast_integrity := true

#endregion Debugging & tests


#region Player Options

var player_options : PlayerOptions

const DEFAULT_USER_NAME : String = "(( you ))"

const ENABLE_AUTO_BRAIN := false

var DEFAULT_MODE_IS_BATTLE : bool :
	get: return player_options.use_default_battle
var AUTO_START_GAME : bool :
	get: return player_options.autostart_map


enum LearnTabs {
	TUTORIAL = 1,
	PUZZLE = 2,
	CAMPAIGN = 3,
	SYMBOLS_WIKI = 5,
	MAGIC_WIKI = 6,
}

var LAST_OPENED_LEARN_TAB : LearnTabs :
	get: return player_options.last_open_learn_tab

enum MainMenuTabs {
	SERVER = 0,
	JOIN = 1,
	SETTINGS = 2,
	CREDITS = 3,
	REPLAYS = 4,
	LEARN = 5,
}

var LAST_OPENED_TAB : MainMenuTabs :
	get: return player_options.last_open_menu_tab

var LAST_USED_BATTLE_PRESET_NAME : String :
	get: return player_options.last_used_battle_preset_name
var LAST_USED_WORLD_MAP : DataWorldMap : # TODO implement this
	get: return player_options.last_used_world_map

var FULLSCREEN_AUTO_TOGGLE : bool :
	get: return player_options.keep_main_menu_windowed


func save_last_used_for_host_setup(\
		address : String, port : int, username : String) -> void:
	player_options.login = username
	player_options.last_hosting_address_used = address
	player_options.last_hosting_port_used = port
	save_player_options()


func save_last_used_for_joining(\
		address : String, port : int,\
		username : String, randomise_join_login : bool) -> void:
	player_options.login = username
	player_options.randomise_join_login = randomise_join_login
	player_options.last_remote_host_address = address
	player_options.last_remote_host_port = port
	save_player_options()


func get_username() -> String:
	return player_options.login


func _init():
	if FileAccess.file_exists(PLAYER_OPTIONS_PATH):
		player_options = load(PLAYER_OPTIONS_PATH)
	if not player_options:
		player_options = PlayerOptions.new()
		save_player_options()

func save_player_options():
	ResourceSaver.save(player_options, PLAYER_OPTIONS_PATH)

#endregion Player Options
