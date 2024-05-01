extends GutTest

const ALLOWED_BATTLE_TILE_TYPES = {
	"sentinel" : true,
	"blue_spawn": true,
	"empty": true,
	"red_spawn": true,
	"wall": true,
	"swamp": true,
	"hole": true,
}

func test_battle_tiles_set():
	gut.p("Testing battle tiles set")
	var tile_types_seen = {}
	var tiles = FileSystemHelpers.list_files_in_folder(CFG.BATTLE_MAP_TILES_PATH, true)
	for tile_path in tiles:
		gut.p("Checking " + tile_path)
		var tile = load(tile_path)
		assert_true(ALLOWED_BATTLE_TILE_TYPES.has(tile.type), \
			"Invalid tile type \"%s\" allowed types: %s" % \
			[tile.type, str(ALLOWED_BATTLE_TILE_TYPES.keys())])
		if not tile_types_seen.has(tile.type):
			tile_types_seen[tile.type] = 0
		tile_types_seen[tile.type] += 1
		assert_file_exists(tile.texture_path)
	for expected_type in ALLOWED_BATTLE_TILE_TYPES.keys():
		assert_true(tile_types_seen.has(expected_type), \
			"No tile exists with type \"%s\"" % expected_type)


func test_battle_maps():
	gut.p("Testing battle maps %s" % CFG.BATTLE_MAPS_PATH)
	var map_paths = FileSystemHelpers.list_files_in_folder(CFG.BATTLE_MAPS_PATH, true)
	for path in map_paths:
		gut.p("Checking "+path)
		var map_data : DataBattleMap = load(path)
		assert_between(map_data.max_player_number, 2, 2, "max_player_number")
		var tile_types_seen = {}
		for x in range(map_data.grid_width):
			for y in range(map_data.grid_height):
				var tile : DataTile = map_data.grid_data[x][y]
				assert_file_exists(tile.texture_path)
				assert_true(ALLOWED_BATTLE_TILE_TYPES.has(tile.type), \
					"Invalid tile type \"%s\" at %s allowed types: %s" % \
					[tile.type, str([x,y]), str(ALLOWED_BATTLE_TILE_TYPES.keys())])
				if not tile_types_seen.has(tile.type):
					tile_types_seen[tile.type] = 0
				tile_types_seen[tile.type] += 1
		assert_between(tile_types_seen["blue_spawn"], 2,5,"blue_spawn")
		assert_between(tile_types_seen["red_spawn"], 2,5,"red_spawn")
		gut.p([tile_types_seen["blue_spawn"], tile_types_seen["red_spawn"]])

