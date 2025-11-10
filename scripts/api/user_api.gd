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
		headers,
		UserModels.TokenResponse.from_json
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
	
	# Success - data is already parsed as TokenResponse
	return {
		"success": true,
		"data": response.data
	}


static func get_user_game_info() -> Dictionary:
	return await ApiHelper.authenticated_request_with_refresh(
		BASE_URL + "/users/me/game-info",
		HTTPClient.METHOD_GET,
		"",
		[],
		UserModels.ReadUserGameInfoResponse.from_json
	)
