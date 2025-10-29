extends Control

@onready var username_input = $Login/UsernameInput
@onready var password_input = $Login/PasswordInput
@onready var http_request = HTTPRequest.new()

func _ready():
	add_child(http_request)
	http_request.request_completed.connect(_on_login_response)
	http_request.set_tls_options(TLSOptions.client_unsafe())

func _on_server_button_pressed() -> void:
	NetworkHandler.start_server()

func _on_login_button_pressed() -> void:
	var username = username_input.text
	var password = password_input.text
	
	if username.is_empty() or password.is_empty():
		print("Please fill all fields")
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
		print("Request failed with error: ", error)
	
	
func _on_login_response(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print("Login successful: ", json)
		
		# Handle successful login (e.g., store token)
		ClientNetworkGlobals.username = username_input.text
		
		NetworkHandler.start_client()
		ClientNetworkGlobals.handle_local_id_assignment.connect(_on_id_assigned)
		visible = false
	else:
		print("Login failed with code: ", response_code)
		print("Response: ", body.get_string_from_utf8())

func _on_id_assigned(local_id: int) -> void:
	print("ID assigned: ", local_id, " Sending username: ", ClientNetworkGlobals.username)
	PlayerUsername.create(local_id, ClientNetworkGlobals.username).send(NetworkHandler.server_peer)
