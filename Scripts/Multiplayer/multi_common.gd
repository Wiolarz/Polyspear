class_name MultiCommon

static func decode_packet(packet : PackedByteArray):
	var result = bytes_to_var(packet)
	if result is Dictionary and "name" in result and result["name"] is String:
		return result
	return null
