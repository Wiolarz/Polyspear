extends GutTest


var levels = []

var managers = {}


func before_all():
	gut.p("Runs once before all tests")
	"""
	var level_paths : Array[String] = TestTools.list_files_in_folder("res://Scenes/Levels/")
	for level in level_paths:
		var test_map = load("res://Scenes/Levels/" + level)
		test_map = test_map.instantiate()
		levels.append(test_map)
		managers[level] = test_map.get_node("WorldSetup")
	"""

func before_each():
	gut.p("start")

func after_each():
	gut.p("end")

func after_all():
	gut.p("Runs once after all tests")

	#for level in levels:
		#level.free()


"""

func test_assert_eq_number_not_equal():
	assert_eq(1, 2, 'Should fail.  1 != 2')

func test_assert_eq_number_equal():
	assert_eq('asdf', 'asdf', 'Should pass')
"""


#func test_map_generation():


func test_tiles_assigned():
	assert_true(B_GRID.SentineltHexTile != null, " No Sentinel tile")
	assert_true(B_GRID.DefaultHexTile != null, " No Default tile")
	assert_true(B_GRID.AttackerHexTile != null, " No Attacker tile")
	assert_true(B_GRID.DefenderHexTile != null, " No Defender tile")



func test_generate_grid():
	"""
	for level in managers.keys():
		var manager = managers[level]
		manager.generate_grid()
		
		assert_eq(level + " Different number of starting tiles: A:"
		+ str(manager.AttackerTiles.size()) + " D:" + str(manager..size())
		)
	"""

