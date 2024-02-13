extends GutTest


var levels = []

var managers = {}


func before_all():
	gut.p("Runs once before all tests")

	var level_paths : Array[String] = list_files_in_folder("res://Scenes/Levels/")
	for level in level_paths:
		var test_map = load("res://Scenes/Levels/" + level)
		test_map = test_map.instantiate()
		levels.append(test_map)
		managers[level] = test_map.get_node("GridManager")


func before_each():
	gut.p("Runs before each test.")

func after_each():
	gut.p("Runs after each test.")

func after_all():
	gut.p("Runs once after all tests")

	for level in levels:
		level.free()


"""

func test_assert_eq_number_not_equal():
	assert_eq(1, 2, 'Should fail.  1 != 2')

func test_assert_eq_number_equal():
	assert_eq('asdf', 'asdf', 'Should pass')
"""


#func test_map_generation():


func list_files_in_folder(folder_path: String) -> Array[String]:
	var dir = DirAccess.open(folder_path)
	var scenes:Array[String] = []

	if dir:
		for file in dir.get_files():
			#scenes.append(folder_path + "/" + file)
			scenes.append(file)
	else:
		print("Error opening folder:", folder_path)
	dir = null
	return scenes


func test_tiles_assigned():
	
	for level in managers.keys():
		var manager = managers[level]
		assert_true(manager.SentineltHexTile != null, level + " No Sentinel tile")
		assert_true(manager.DefaultHexTile != null, level + " No Default tile")
		assert_true(manager.AttackerHexTile != null, level + " No Attacker tile")
		assert_true(manager.DefenderHexTile != null, level + " No Defender tile")
		


func test_GenerateGrid():
	for level in managers.keys():
		var manager = managers[level]
		manager.GenerateGrid()
		
		

		assert_eq(
			manager.AttackerTiles.size(), manager.DefenderTiles.size(),
			level + " Different number of starting tiles: A:" + str(manager.AttackerTiles.size()) + " D:" + str(manager.DefenderTiles.size())
		)

