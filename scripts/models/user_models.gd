class_name UserModels


class LoginRequest:
	var user_name: String
	var password: String
	
	func _init(username: String, pwd: String) -> void:
		user_name = username
		password = pwd
	
	func to_json() -> Dictionary:
		return {
			"userName": user_name,
			"password": password
		}


class TokenResponse:
	var access_token: String
	var expires_in_seconds: int
	var refresh_token: String
	
	func _init(data: Dictionary = {}) -> void:
		access_token = data.get("accessToken")
		expires_in_seconds = data.get("expiresInSeconds")
		refresh_token = data.get("refreshToken")
	
	static func from_json(data: Dictionary) -> TokenResponse:
		return TokenResponse.new(data)


class ReadUserGameInfoResponse:
	var account_guid: String
	var user_name: String
	var balance: int
	
	func _init(data: Dictionary = {}) -> void:
		account_guid = data.get("id")
		user_name = data.get("userName")
		balance = data.get("balance")
	
	static func from_json(data: Dictionary) -> ReadUserGameInfoResponse:
		return ReadUserGameInfoResponse.new(data)


class UpdateUserCustomizationRequest:
	var body_color: String
	var eye_color: String
	var wing_color: String
	var horn_color: String
	var markings_color: String
	var wing_type: int
	var horn_type: int
	var markings_type: int

	func _init(body_color: Color,
			eye_color: Color,
			wing_color: Color,
			horn_color: Color,
			markings_color: Color,
			wing_type: int,
			horn_type: int,
			markings_type: int) -> void:
		self.body_color =  "#" + body_color.to_html()
		self.eye_color = "#" + eye_color.to_html()
		self.wing_color = "#" + wing_color.to_html()
		self.horn_color = "#" + horn_color.to_html()
		self.markings_color = "#" + markings_color.to_html()
		self.wing_type = wing_type
		self.horn_type = horn_type
		self.markings_type = markings_type
	
	func to_json() -> Dictionary:
		return {
			"bodyColor": body_color,
			"eyeColor": eye_color,
			"wingColor": wing_color,
			"hornColor": horn_color,
			"markingsColor": markings_color,
			"wingType": wing_type,
			"hornType": horn_type,
			"markingsType": markings_type
		}



class ReadUserCustomizationResponse:
	var body_color: Color
	var eye_color: Color
	var wing_color: Color
	var horn_color: Color
	var markings_color: Color
	var wing_type: int
	var horn_type: int
	var markings_type: int
	var user_id: String
	
	func _init(data: Dictionary = {}) -> void:
		body_color = Color(data.get("bodyColor"))
		eye_color = Color(data.get("eyeColor"))
		wing_color = Color(data.get("wingColor"))
		horn_color = Color(data.get("hornColor"))
		markings_color = Color(data.get("markingsColor"))
		wing_type = data.get("wingType")
		horn_type = data.get("hornType")
		markings_type = data.get("markingsType")
		user_id = data.get("userId")