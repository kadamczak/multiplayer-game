class_name UserAPI

const BASE_URL = "https://localhost:7110/v1"

static func login(username: String, password: String) -> Dictionary:
	var http_request = HTTPRequest.new()
	http_request.set_tls_options(TLSOptions.client_unsafe())
	
	var scene_root = Engine.get_main_loop().root
	scene_root.add_child(http_request)
	
	var request_model = UserModels.LoginRequest.new(username, password)
	var body = JSON.stringify(request_model.to_json())
	
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json",
		"X-Client-Type: Game"
	]
	
	var error = http_request.request(
		BASE_URL + "/identity/login",
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	
	if error != OK:
		http_request.queue_free()
		return {"success": false, "error": "Request failed: " + str(error)}
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var response_code = response[1]
	var response_body = response[3]
	
	if response_code == 200:
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		if json != null:
			var login_response = UserModels.TokenResponse.from_json(json)
			return {
				"success": true,
				"data": login_response
			}
		else:
			return {"success": false, "error": "Invalid JSON response"}
	else:
		var response_text = response_body.get_string_from_utf8()
		var json = JSON.parse_string(response_text)
		var error_message = "Login failed"
		
		if json != null and json.has("errors"):
			var error_messages = []
			for error_array in json["errors"].values():
				for error_msg in error_array:
					error_messages.append(error_msg)
			error_message = "\n".join(error_messages)
		elif json != null and json.has("title"):
			error_message = json["title"]
		else:
			error_message = response_text
		
		return {
			"success": false,
			"error": error_message,
			"response_code": response_code
		}


static func get_user_game_info() -> Dictionary:
	var response = await AuthManager.make_authenticated_request(
		BASE_URL + "/users/me/game-info",
		HTTPClient.METHOD_GET
	)
	
	var result = response[0]
	var response_code = response[1]
	var response_body = response[3]
	
	if result != OK:
		return {"success": false, "error": "Request failed: " + str(result)}
	
	if response_code == 200:
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		if json != null:
			var user_info = UserModels.ReadUserGameInfoResponse.from_json(json)
			return {
				"success": true,
				"data": user_info
			}
		else:
			return {"success": false, "error": "Invalid JSON response"}
	else:
		return {
			"success": false,
			"error": "Failed to fetch user info",
			"response_code": response_code
		}
