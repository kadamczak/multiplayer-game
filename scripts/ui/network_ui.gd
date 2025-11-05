extends Control

@onready var login_panel = $Login
@onready var username_input = $Login/UsernameInput
@onready var password_input = $Login/PasswordInput
@onready var error_label = $Login/ErrorLabel
@onready var http_request = HTTPRequest.new()

var is_dedicated_server := false
var is_auto_login_attempted := false

func _ready():
	add_child(http_request)
	http_request.request_completed.connect(_on_login_response)
	http_request.set_tls_options(TLSOptions.client_unsafe())
	
	# Check command line arguments for dedicated server mode
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg == "--server" or arg == "--dedicated-server":
			is_dedicated_server = true
			break
	
	# If dedicated server, skip login and load hub directly
	if is_dedicated_server:
		NetworkHandler.start_server()
		get_tree().change_scene_to_file("res://scenes/levels/hub.tscn")
		return
	
	# Attempt automatic login with saved refresh token
	_attempt_auto_login()


func _attempt_auto_login() -> void:
	is_auto_login_attempted = true
	
	# Hide login panel and show loading state
	login_panel.visible = false
	error_label.text = "Attempting automatic login..."
	error_label.visible = true
	
	DebugLogger.log("Attempting automatic login from saved token...")
	
	var success = await AuthManager.attempt_auto_login()
	
	if success:
		DebugLogger.log("Auto-login successful, fetching user info...")
		
		# Fetch user info to get username
		var username = await _fetch_user_info()
		
		if username.is_empty():
			DebugLogger.log("Failed to fetch user info, falling back to login screen")
			login_panel.visible = true
			error_label.visible = false
			return
		
		ClientNetworkGlobals.username = username
		DebugLogger.log("Auto-login complete with username: " + username)
		
		# Start client connection
		NetworkHandler.start_client()
		
		# Switch to hub scene
		get_tree().change_scene_to_file("res://scenes/levels/hub.tscn")
	else:
		DebugLogger.log("Auto-login failed, showing login screen")
		
		# Show login panel
		login_panel.visible = true
		error_label.visible = false


func _fetch_user_info() -> String:
	var user_http = HTTPRequest.new()
	add_child(user_http)
	user_http.set_tls_options(TLSOptions.client_unsafe())
	
	# Make authenticated request
	var headers = [
		"Authorization: " + AuthManager.get_auth_header(),
		"Accept: application/json"
	]
	
	var error = user_http.request(
		"https://localhost:7110/v1/identity/user",
		headers,
		HTTPClient.METHOD_GET
	)
	
	if error != OK:
		DebugLogger.log("Failed to request user info: " + str(error))
		user_http.queue_free()
		return ""
	
	var response = await user_http.request_completed
	user_http.queue_free()
	
	var response_code = response[1]
	var response_body = response[3]
	
	if response_code == 200:
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		if json != null and json.has("userName"):
			return json.get("userName", "")
	
	DebugLogger.log("Failed to fetch user info, response code: " + str(response_code))
	return ""

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
	
	var error = http_request.request( #1
		"https://localhost:7110/v1/identity/login",
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	
	if error != OK:
		DebugLogger.log("Request failed with error: " + str(error))
		return


func _on_login_response(_result, response_code, _headers, body):
	if response_code == 200: #2
		var json = JSON.parse_string(body.get_string_from_utf8())
		DebugLogger.log("Login successful: " + str(json))
		
		# Extract and store tokens securely
		var access_token = json.get("accessToken", "")
		var refresh_token = json.get("refreshToken", "")
		var expires_in = json.get("expiresIn", 3600)
		
		if not access_token.is_empty() and not refresh_token.is_empty():
			AuthManager.store_tokens(access_token, refresh_token, expires_in)
			DebugLogger.log("Tokens stored securely")
		else:
			push_warning("Login response missing tokens")
		
		# Store username
		ClientNetworkGlobals.username = username_input.text #3
		
		# Start client connection
		NetworkHandler.start_client() #4
		
		# Switch to hub scene
		get_tree().change_scene_to_file("res://scenes/levels/hub.tscn")
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


# start_client -> server connection
# server broadcasts client IDAssignment ->
# after receiving IDAssignment on client, send PlayerUsername to server -> server broadcasts to all clients
