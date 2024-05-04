class_name RequestFactionCycleCommand

const COMMAND_NAME = "request_faction_cycle"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(RequestFactionCycleCommand.process_command)

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
	var faction_index = CFG.FACTIONS_LIST.find(slot.faction)
	var new_faction_index = \
		(faction_index + diff) % CFG.FACTIONS_LIST.size()
	slot.faction = CFG.FACTIONS_LIST[new_faction_index]
	server.broadcast_full_game_setup(IM.game_setup_info)
	IM.game_setup_info_changed.emit()
	return OK
