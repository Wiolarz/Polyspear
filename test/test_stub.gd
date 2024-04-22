"""
STUB - example test template showing some basics
"""

extends GutTest


func before_all():
	gut.p("STUB - Runs once before all tests")

func before_each():
	gut.p("STUB - Runs before each test")

func after_each():
	gut.p("STUB - Runs after each test")

func after_all():
	gut.p("STUB - Runs once after all tests")


func test_simple_logic_example() -> void:
	gut.p("STUB - running test_simple_logic_example")
	# pick log level to have more or less verbose info
	# default log level is 0
	# default visibility in test runner is <= 1
	var log_level = 1
	gut.p("This is info visible by default in test runner", log_level)
	gut.p("This will noty be displayed without increasing log level", log_level + 1)
	# Arrange / Given:
	var bool1 = true
	var bool2 = false
	# Act / When:
	var result = bool1 and bool2
	# Assert / Then:
	assert_false(result, "Custom error information")

func test_another_example() -> void:
	gut.p("STUB - running test_another_example")

	var bool1 = true
	var bool2 = true

	var result = bool1 and bool2

	assert_true(result, "Wtf just happened")

var example_params = ParameterFactory.named_parameters(
	 # names
	['p1', 'p2', 'expected_result'],
	# values (size must match names size)
	[
		[1, 2, 3],
		['a', 'b', 'ab']
	])

func test_parametrised_example(params = use_parameters(example_params)):
	var result = params.p1 + params.p2
	assert_eq(result, params.expected_result)
