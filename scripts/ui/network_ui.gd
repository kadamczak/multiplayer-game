extends Control

@onready var login_panel = $Login
@onready var username_input = $Login/UsernameInput
@onready var password_input = $Login/PasswordInput
@onready var error_label = $Login/ErrorLabel
@onready var http_request = HTTPRequest.new()

var is_dedicated_server := false

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
		print("Request failed with error: ", error)
	
	
func _on_login_response(_result, response_code, _headers, body):
	if response_code == 200: #2
		var json = JSON.parse_string(body.get_string_from_utf8())
		print("Login successful: ", json)
		
		# Extract and store tokens securely
		#var access_token = json.get("accessToken", "")
		#var refresh_token = json.get("refreshToken", "")
		#var expires_in = json.get("expiresIn", 3600)
		
		# if not access_token.is_empty() and not refresh_token.is_empty():
		# 	AuthManager.store_tokens(access_token, refresh_token, expires_in)
		# 	print("Tokens stored securely")
		# else:
		# 	push_warning("Login response missing tokens")
		
		# Store username
		ClientNetworkGlobals.username = username_input.text #3
		
		# Start client connection
		NetworkHandler.start_client() #4
		
		# Switch to hub scene
		get_tree().change_scene_to_file("res://scenes/levels/hub.tscn")
	else:
		print("Login failed with code: ", response_code)
		print("Response: ", body.get_string_from_utf8())

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
