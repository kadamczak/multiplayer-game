extends Control

@onready var login_panel = $Login
@onready var username_input = $Login/UsernameInput
@onready var password_input = $Login/PasswordInput
@onready var stay_logged_in_checkbox = $Login/StayLoggedInCheckbox
@onready var error_label = $Login/ErrorLabel
@onready var http_request = HTTPRequest.new()

func _ready():
	add_child(http_request)
	http_request.request_completed.connect(_on_login_response)
	http_request.set_tls_options(TLSOptions.client_unsafe())
	
	if is_dedicated_server():
		NetworkHandler.start_server()
		return
	
	_attempt_auto_login()


func is_dedicated_server() -> bool:
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg == "--server" or arg == "--dedicated-server":
			return true
	return false

func _on_login_button_pressed() -> void:
	var username = username_input.text
	var password = password_input.text
	
	if username.is_empty() or password.is_empty():
		error_label.text = "Please fill in all fields."
		error_label.visible = true
		return
		
	var body = JSON.stringify({
		"UserName": username,
		"Password": password
	})
	
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json",
		"X-Client-Type: Game"
	]
	
	var error = http_request.request(
		"https://localhost:7110/v1/identity/login",
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	
	if error != OK:
		DebugLogger.log("Request failed with error: " + str(error))
		return


func _on_login_response(_result, response_code, _headers, body):
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		var access_token = json.get("accessToken", "")
		var refresh_token = json.get("refreshToken", "")

		if access_token.is_empty() or refresh_token.is_empty():
			DebugLogger.log("Login response missing tokens")
			error_label.text = "Login failed: Missing tokens in response."
			error_label.visible = true
			return
		
		var stay_logged_in = stay_logged_in_checkbox.button_pressed
		AuthManager.store_tokens(access_token, refresh_token, stay_logged_in)

		var user_info = await _fetch_user_info()

		if user_info == null:
			DebugLogger.log("Failed to fetch user info, falling back to login screen")
			login_panel.visible = true
			return

		_successfully_log_in(user_info.userName, user_info.balance)
	else:
		DebugLogger.log("Login failed with code: " + str(response_code))
		DebugLogger.log("Response: " + body.get_string_from_utf8())

		var response_text = body.get_string_from_utf8()
		var json = JSON.parse_string(response_text)

		if json != null and json.has("errors"):
			var error_messages = []
			for error_array in json["errors"].values():
				for error_msg in error_array:
					error_messages.append(error_msg)
			error_label.text = "\n".join(error_messages)
		elif json != null and json.has("title"):
			error_label.text = json["title"]
		else:
			error_label.text = "Login failed: " + response_text
		
		error_label.visible = true


func _attempt_auto_login() -> void:	
	login_panel.visible = false
	DebugLogger.log("Attempting automatic login from saved token...")
	
	var success = await AuthManager.attempt_auto_login()
	
	if success:
		DebugLogger.log("Auto-login successful, fetching user info...")
		
		var user_info = await _fetch_user_info()
		
		if user_info == null:
			DebugLogger.log("Failed to fetch user info, falling back to login screen")
			login_panel.visible = true
			return

		_successfully_log_in(user_info.userName, user_info.balance)
	else:
		DebugLogger.log("Auto-login failed, showing login screen")
		login_panel.visible = true


func _fetch_user_info():
	var headers = [
		"Authorization: " + AuthManager.get_auth_header(),
		"Accept: application/json"
	]
	
	var error = http_request.request(
		"https://localhost:7110/v1/users/me/game-info",
		headers,
		HTTPClient.METHOD_GET
	)
	
	if error != OK:
		DebugLogger.log("Failed to request user info: " + str(error))
		return null
	
	var response = await http_request.request_completed
	
	var response_code = response[1]
	var response_body = response[3]
	
	if response_code == 200:
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		if json != null and json.has("userName") and json.has("balance"):
			return json

	DebugLogger.log("Failed to fetch user info, response code: " + str(response_code))
	return null


func _successfully_log_in(username: String, balance: int) -> void:
	ClientNetworkGlobals.username = username
	ClientNetworkGlobals.balance = balance

	NetworkHandler.start_client()
	get_tree().change_scene_to_file("res://scenes/levels/hub.tscn")
