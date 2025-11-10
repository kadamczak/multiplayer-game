class_name UserAPI

static func get_user_game_info() -> Dictionary:
	return await ApiHelper.authenticated_request_with_refresh(
		ApiConfig.API_BASE_URL + "/v1/users/me/game-info",
		HTTPClient.METHOD_GET,
		[],
		"",
		UserModels.ReadUserGameInfoResponse.from_json
	)
	
