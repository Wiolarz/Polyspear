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

	"""
