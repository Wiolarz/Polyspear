class_name Player
extends Node

var slot : GameSetupInfo.Slot

var bot_engine : AIInterface

var index : int:
	get: return slot.index
	set(_value): assert(false, "no set here")

var team : int:
	get: return slot.team
	set(_value): assert(false, "no set here")

static func create(new_slot : GameSetupInfo.Slot) -> Player:
	var result := Player.new()
	result.slot = new_slot

	if new_slot.is_bot():
		result.bot_engine = ExampleBot.new(result)
		result.add_child(result.bot_engine)
	result.name = "Player_" + result.get_player_name()

	return result


func _init(): #?
	name = "Player"


#region Getters

func get_player_name() -> String:
	# TODO make these names same as elsewhere
	if slot.is_bot():
		return "AI"
	if slot.is_local():
		return "LOCAL" # TODO use the same identifier which is "(( you ))" when
					   # offline
	# network login
	return slot.occupier


func get_player_color() -> DataPlayerColor:
	return CFG.TEAM_COLORS[slot.color]


func get_faction() -> DataFaction:
	# TODO store faction in state
	return slot.faction

#endregion Getters


## let player know its his turn,
## in case play is AI, call his decision maker
func your_turn(battle_state : BattleGridState):
	var color_name = CFG.TEAM_COLORS[slot.color].name
	print("your move %s - %s" % [get_player_name(), color_name])

	if bot_engine != null and not NET.client: # AI is simulated on server only
		bot_engine.play_move(battle_state)


## Checks if player has enough goods for purchase
func has_enough(world_state : WorldState, cost : Goods) -> bool:
	return world_state.has_player_enough(index, cost)


## If there are sufficient goods returns true + goods are subtracted
func purchase(world_state : WorldState, cost : Goods) -> bool:
	return world_state.player_purchase(index, cost)


#region Heroes

## it is probably called in some signal -- TODO document it or get rid of it
func hero_recruited(hero : ArmyForm):
	pass
	# probably delete this xD
	#world_state.player_recruit_hero(index, hero)
	#wps.hero_armies.append(hero)


#func hero_died(hero : Hero):
	#var i = 0
	#while i < wps.hero_armies.size():
		#if wps.hero_armies[i].entity.hero == hero:
			#wps.hero_armies.remove_at(i)
		#else:
			#i += 1

	#wps.dead_heroes.append(hero)


func has_hero(world_state : WorldState, data_hero: DataHero):
	return world_state.has_player_a_hero(index, data_hero)


func has_dead_hero(world_state : WorldState, data_hero: DataHero):
	return world_state.has_player_a_dead_hero(index, data_hero)


func get_hero_cost(world_state : WorldState, data_hero: DataHero):
	return world_state.get_hero_cost_for_player(index, data_hero)

#endregion Heroes


#region Outposts

func outpost_add(world_state : WorldState, outpost : Outpost) -> void:
	pass
	#world_state
	#wps.outposts.append(outpost)

func outpost_remove(outpost : Outpost) -> void:
	pass
	#assert(outpost in wps.outposts, "attempt to remove outpost that wasnt assigned to the player")

	#wps.outposts.erase(outpost)

	#if not outpost_requirement(outpost.outpost_type):
	#	outpost_demolish(outpost.outpost_type)
#
#func outpost_requirement(outpost_type_needed : String) -> bool:
	#if outpost_type_needed == "":
		#return true
	#for outpost in wps.outposts:
		#if outpost.outpost_type == outpost_type_needed:
			#return true
	#return false
#
#func outpost_demolish(demolish_type : String):
	#for building_idx in range(wps.outpost_buildings.size() -1, -1, -1):
		#if wps.outpost_buildings[building_idx].outpost_requirement == demolish_type:
			#wps.outpost_buildings.pop_at(building_idx)


#endregion Outposts
