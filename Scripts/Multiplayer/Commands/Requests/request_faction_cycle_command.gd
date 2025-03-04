class_name RequestRaceCycle

const COMMAND_NAME = "race_cycle"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(RequestRaceCycle.process_command)

static func create_packet(slot_index : int, backwards : bool = false):
	return {
		"name": COMMAND_NAME,
		"slot": slot_index,
		"backwards": backwards,
	}

static func process_command(server : Server, peer : ENetPacketPeer, \
		params : Dictionary) -> int:
	var session : Server.Session = server.get_session_by_peer(peer)
	if session == null:
		return FAILED
	if not "slot" in params or not params["slot"] is int:
		return FAILED
	if not "backwards" in params or not params["backwards"] is bool:
		return FAILED
	var slots = IM.game_setup_info.slots
	var diff : int = 1 if not params["backwards"] else -1
	var index = params["slot"] as int
	if index < 0 or index >= slots.size():
		return FAILED
	var slot = slots[index]
	var race_index = CFG.RACES_LIST.find(slot.race)
	var new_race_index = \
		(race_index + diff) % CFG.RACES_LIST.size()
	slot.race = CFG.RACES_LIST[new_race_index]
	server.broadcast_full_game_setup(IM.game_setup_info)
	IM.game_setup_info_changed.emit()
	return OK
