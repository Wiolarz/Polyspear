class_name ServerSettings
extends RefCounted

var content : Dictionary


func allow_slot_steal() -> bool:
	return content.get("allow_slot_steal", true)


func all_can_start() -> bool:
	return content.get("all_can_start", false)
