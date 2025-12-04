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
	var customization: ReadUserCustomizationResponse
	var user_items: Array[ItemModels.ReadUserItemResponse] = []
	
	func _init(data: Dictionary = {}) -> void:
		account_guid = data.get("id")
		user_name = data.get("userName")
		balance = data.get("balance")

		var customization_data = data.get("customization")
		if customization_data == null:
			customization = ReadUserCustomizationResponse.new()
		elif customization_data is Dictionary:
			customization = ReadUserCustomizationResponse.from_json(customization_data)
		else:
			customization = ReadUserCustomizationResponse.new()

		var user_items_data = data.get("userItems", [])
		if user_items_data is Array:
			for item_data in user_items_data:
				if item_data is Dictionary:
					user_items.append(ItemModels.ReadUserItemResponse.from_json(item_data))
	
	static func from_json(data: Dictionary) -> ReadUserGameInfoResponse:
		return ReadUserGameInfoResponse.new(data)


class UpdateUserAppearanceRequest:
	var head_color: String
	var body_color: String
	var tail_color: String
	var eye_color: String
	var wing_color: String
	var horn_color: String
	var markings_color: String

	var head_type: int
	var body_type: int
	var tail_type: int
	var eye_type: int
	var wing_type: int
	var horn_type: int
	var markings_type: int

	func _init(user_appearance: Dictionary) -> void:
		self.head_color = "#" + user_appearance["Head"].color.to_html()
		self.body_color = "#" + user_appearance["Body"].color.to_html()
		self.tail_color = "#" + user_appearance["Tail"].color.to_html()
		self.eye_color = "#" + user_appearance["Eyes"].color.to_html()
		self.wing_color = "#" + user_appearance["Wings"].color.to_html()
		self.horn_color = "#" + user_appearance["Horns"].color.to_html()
		self.markings_color = "#" + user_appearance["Markings"].color.to_html()

		self.head_type = user_appearance["Head"].line_type
		self.body_type = user_appearance["Body"].line_type
		self.tail_type = user_appearance["Tail"].line_type
		self.eye_type = user_appearance["Eyes"].line_type
		self.wing_type = user_appearance["Wings"].line_type
		self.horn_type = user_appearance["Horns"].line_type
		self.markings_type = user_appearance["Markings"].line_type
		

	func to_json() -> Dictionary:
		return {
			"headColor": head_color,
			"bodyColor": body_color,
			"tailColor": tail_color,
			"eyeColor": eye_color,
			"wingColor": wing_color,
			"hornColor": horn_color,
			"markingsColor": markings_color,

			"headType": head_type,
			"bodyType": body_type,
			"tailType": tail_type,
			"eyeType": eye_type,
			"wingType": wing_type,
			"hornType": horn_type,
			"markingsType": markings_type
		}



class ReadUserCustomizationResponse:
	var head_color: Color
	var body_color: Color
	var tail_color: Color
	var eye_color: Color
	var wing_color: Color
	var horn_color: Color
	var markings_color: Color

	var head_type: int
	var body_type: int
	var tail_type: int
	var eye_type: int
	var wing_type: int
	var horn_type: int
	var markings_type: int
	
	var equipped_head_user_item_id: String
	var equipped_body_user_item_id: String
	
	func _init(data: Dictionary = {}) -> void:
		head_color = Color(data.get("headColor"))
		body_color = Color(data.get("bodyColor"))
		tail_color = Color(data.get("tailColor"))
		eye_color = Color(data.get("eyeColor"))
		wing_color = Color(data.get("wingColor"))
		horn_color = Color(data.get("hornColor"))
		markings_color = Color(data.get("markingsColor"))

		head_type = data.get("headType")
		body_type = data.get("bodyType")
		tail_type = data.get("tailType")
		eye_type = data.get("eyeType")
		wing_type = data.get("wingType")
		horn_type = data.get("hornType")
		markings_type = data.get("markingsType")

		equipped_head_user_item_id = data.get("equippedHeadUserItemId")
		equipped_body_user_item_id = data.get("equippedBodyUserItemId")



	static func from_json(data: Dictionary) -> ReadUserCustomizationResponse:
		return ReadUserCustomizationResponse.new(data)
