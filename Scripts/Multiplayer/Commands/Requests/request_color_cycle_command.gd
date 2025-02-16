class_name RequestColorCycle

const COMMAND_NAME = "color_cycle"

static func register(commands : Dictionary):
	commands[COMMAND_NAME] = \
			Command.create_on_server(RequestColorCycle.process_command)

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
	var new_color_index = slots[index].color_idx
	# TODO move this logic elsewhere
	while true:
		new_color_index = (new_color_index + diff) % CFG.TEAM_COLORS.size()
		if new_color_index == slots[index].color_idx: # all colors are taken
			return false
		var is_color_unique = func() -> bool:
			for slot_to_compare in slots:
				if slot_to_compare.color_idx == new_color_index:
					return false
			return true
		if is_color_unique.call():
			slots[index].color_idx = new_color_index
			break
	server.broadcast_full_game_setup(IM.game_setup_info)
	IM.game_setup_info_changed.emit()
	return OK
