class_name PolyApi


static func get_servers_list() -> Array[ServerDescription]:
	var request = HTTPRequest.new()
	NET.add_child(request)
	var url = CFG.POLYAPI_BASE_URL + "polyspear/servers"
	request.request(url)
	var results = await request.request_completed
	# results = [_result, _response_code, _headers, body]
	var json = JSON.new()
	json.parse(results[3].get_string_from_utf8())
	var result : Array[ServerDescription] = []
	var result_data = json.get_data()
	for d in result_data:
		result.append(ServerDescription.new(d))
	request.queue_free()
	return result


static func post_server(description: ServerDescription) -> void:
	await delete_server(description.login)

	var request = HTTPRequest.new()
	NET.add_child(request)

	var url = CFG.POLYAPI_BASE_URL + "polyspear/servers"
	var body = JSON.stringify(description.to_dictionary())

	request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	await request.request_completed
	# results = [_result, _response_code, _headers, body]


static func delete_server(login: String) -> void:
	var request = HTTPRequest.new()
	NET.add_child(request)

	var url = CFG.POLYAPI_BASE_URL + "polyspear/servers/"+login
	request.request(url, [], HTTPClient.METHOD_DELETE)

	await request.request_completed
	# results = [_result, _response_code, _headers, body]


class ServerDescription:
	var login : String
	var address : String
	var port : int
	var description : String

	func _init(d:Dictionary):
		login = d.login
		address = d.address
		port = d.port
		description = d.description

	func to_dictionary() -> Dictionary:
		return {
			"login": login,
			"address": address,
			"port": port,
			"description": description,
		}

	func _to_string():
		return "[%s] %s : %d\n%s" % [login, address, port, description]
