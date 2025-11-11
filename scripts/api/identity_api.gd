class_name IdentityAPI

static func refresh(refresh_token: String) -> Dictionary:
	var body: String = JSON.stringify(refresh_token)

	return await ApiHelper.api_request(
		ApiConfig.API_BASE_URL + "/v1/identity/refresh",
		HTTPClient.METHOD_POST,
		["X-Client-Type: Game"],
		body,
		UserModels.TokenResponse.from_json
	)


static func logout(refresh_token: String) -> Dictionary:
	var body: String = JSON.stringify(refresh_token)

	return await ApiHelper.api_request(
		ApiConfig.API_BASE_URL + "/v1/identity/logout",
		HTTPClient.METHOD_POST,
		["X-Client-Type: Game"],
		body
	)


static func login(username: String, password: String) -> Dictionary:
	var request_model = UserModels.LoginRequest.new(username, password)
	var body = JSON.stringify(request_model.to_json())
	
	var response = await ApiHelper.api_request(
		ApiConfig.API_BASE_URL + "/v1/identity/login",
		HTTPClient.METHOD_POST,
		["X-Client-Type: Game"],
		body,
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
			"problem": error_message,
		}
	
	return {
		"success": true,
		"data": response.data
	}


