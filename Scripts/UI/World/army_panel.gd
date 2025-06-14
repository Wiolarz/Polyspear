extends UnitsButtonsList


const UNIT_ICON_SIZE : float = 100.0

@onready var units_box_first_row : BoxContainer = $Units/FirstRow
@onready var units_box_second_row : BoxContainer = $Units/SecondRow


var loaded_army : Army


func load_army(army : Army):
	loaded_army = army

	# city garrison allows player to enter it, even though there is no hero in second army
	if not army.hero:
		var city : City = WS.get_city_at(army.coord)
		if city:
			$HeroIcon.texture = load(WS.grid.get_hex(city.coord).data_tile.texture_path)
			$ArmyLabel.text = "City Garrison"
		else:  # Neutral camp/ outpost garrison
			assert(army.units_data.size() > 0, "There shouldn't exist empty neutral army/outpost garrison")
			$HeroIcon.texture = load(army.units_data[0].texture_path)
			$ArmyLabel.text = "Neutral Army"

	else:
		$ArmyLabel.text = army.hero.hero_name
		$HeroIcon.texture = load(army.hero.data_unit.texture_path)

	load_unit_buttons(army, army.units_data, [units_box_first_row, units_box_second_row], UNIT_ICON_SIZE, true, false)
