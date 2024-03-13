"""
STUB
"""

extends GutTest


func before_all():
	gut.p("Runs once before all tests")


func before_each():
	gut.p("start")

func after_each():
	gut.p("end")

func after_all():
	gut.p("Runs once after all tests")



func test_BASIC_UNIT_SETUP() -> void:
	"""
	for i in range(attacker_units.size()):
	
		if i < attacker_units.size():

			input_listener(attacker_units[i].cord)
			input_listener(attacker_units[i].cord + B_GRID.DIRECTIONS[0])

		if i < defender_units.size():

			input_listener(defender_units[i].cord)
			input_listener(defender_units[i].cord + B_GRID.DIRECTIONS[3])

	"""
