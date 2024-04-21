"""
Tests if all WorldSetup Node in all levels have their properties set
"""

extends GutTest


var levels = []

var managers = {}


func before_all():
	gut.p("Runs once before all tests")

	var level_paths : Array[String] = TestTools.list_files_in_folder("res://Scenes/Levels/")
	for level in level_paths:
		var test_map = load("res://Scenes/Levels/" + level)
		test_map = test_map.instantiate()
		levels.append(test_map)
		managers[level] = test_map.get_node("WorldSetup")


func before_each():
	gut.p("start")

func after_each():
	gut.p("end")

func after_all():
	gut.p("Runs once after all tests")

	for level in levels:
		level.free()


func test_tiles_assigned():

	for level in managers.keys():
		var manager = managers[level]
		assert_true(manager.map_data != null, level + " No map data")




