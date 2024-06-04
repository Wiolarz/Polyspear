extends Resource
class_name SerializableWorldState

@export var something : String


static func get_network_serialized(_world_state : SerializableWorldState) \
		-> PackedByteArray:
	return PackedByteArray()


static func from_network_serialized(_ser : PackedByteArray):
	return SerializableWorldState.new()
