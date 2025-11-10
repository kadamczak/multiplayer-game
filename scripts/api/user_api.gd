class_name UserAPI

const BASE_URL = "https://localhost:7110/v1"

static func login(username: String, password: String) -> Dictionary:
	var request_model = UserModels.LoginRequest.new(username, password)
	var body = JSON.stringify(request_model.to_json())
	
	var headers = ["X-Client-Type: Game"]
	
	var response = await ApiHelper.api_request(
		BASE_URL + "/identity/login",
		HTTPClient.METHOD_POST,
		body,
		headers
	)
	
	if not response.success:
		var problem: ApiResponse.ProblemDetails = response.problem
		var error_message = problem.title
		
		# Extract field errors if present
		if not problem.errors.is_empty():
			var field_errors = ApiResponse.get_field_errors(problem)
			var error_messages = []
			for error_text in field_errors.values():
				error_messages.append(error_text)
			error_message = "\n".join(error_messages)
		
		return {
			"success": false,
			"error": error_message,
			"response_code": problem.status
		}
	
	# Success - parse token response
	var login_response = UserModels.TokenResponse.from_json(response.data)
	return {
		"success": true,
		"data": login_response
	}


static func get_user_game_info() -> Dictionary:
	var response = await ApiHelper.make_authenticated_request(
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
