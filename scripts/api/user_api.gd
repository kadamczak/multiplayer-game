class_name UserAPI

static func get_user_game_info() -> Dictionary:
	return await ApiHelper.authenticated_request_with_refresh(
		ApiConfig.API_BASE_URL + "/v1/users/me/game-info",
		HTTPClient.METHOD_GET,
		[],
		"",
		UserModels.ReadUserGameInfoResponse.from_json
	)
	
static func update_user_customization(
	body_color: Color,
	eye_color: Color,
	wing_color: Color,
	horn_color: Color,
	markings_color: Color,
	wing_type: int,
	horn_type: int,
	markings_type: int
) -> Dictionary:

	var request_model = UserModels.UpdateUserCustomizationRequest.new(
		body_color, eye_color, wing_color, horn_color, markings_color, wing_type, horn_type, markings_type
	)
	var body: String = JSON.stringify(request_model.to_json())

	return await ApiHelper.authenticated_request_with_refresh(
		ApiConfig.API_BASE_URL + "/v1/users/me/customization",
		HTTPClient.METHOD_PUT,
		[],
		body
	)
