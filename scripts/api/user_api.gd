class_name UserAPI

static func get_user_game_info() -> Dictionary:
	return await ApiHelper.authenticated_request_with_refresh(
		ApiConfig.API_BASE_URL + "/v1/users/me/game-info?includeCustomization=true",
		HTTPClient.METHOD_GET,
		[],
		"",
		UserModels.ReadUserGameInfoResponse.from_json
	)
	
static func update_user_customization(
	request: UserModels.UpdateUserCustomizationRequest
) -> Dictionary:
	var body: String = JSON.stringify(request.to_json())

	return await ApiHelper.authenticated_request_with_refresh(
		ApiConfig.API_BASE_URL + "/v1/users/me/customization",
		HTTPClient.METHOD_PUT,
		[],
		body
	)
