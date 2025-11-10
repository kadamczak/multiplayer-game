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
	var user_name: String
	var balance: int
	
	func _init(data: Dictionary = {}) -> void:
		user_name = data.get("userName")
		balance = data.get("balance")
	
	static func from_json(data: Dictionary) -> ReadUserGameInfoResponse:
		return ReadUserGameInfoResponse.new(data)
