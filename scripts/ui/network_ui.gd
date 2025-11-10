extends Control

@onready var login_panel = $Login
@onready var username_input = $Login/UsernameInput
@onready var password_input = $Login/PasswordInput
@onready var stay_logged_in_checkbox = $Login/StayLoggedInCheckbox
@onready var error_label = $Login/ErrorLabel


func _ready():
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
	
	var result = await IdentityAPI.login(username, password)
	
	if result.success:
		var login_response: UserModels.TokenResponse = result.data
		var stay_logged_in = stay_logged_in_checkbox.button_pressed

		AuthManager.set_stay_logged_in(stay_logged_in)
		AuthManager.store_tokens(login_response.access_token, login_response.refresh_token)
		
		var user_info_response = await UserAPI.get_user_game_info()
		
		if user_info_response.success:
			var user_info: UserModels.ReadUserGameInfoResponse = user_info_response.data
			_successfully_log_in(user_info.user_name, user_info.balance)
		else:
			DebugLogger.log("Failed to fetch user info: " + user_info_response.problem.title)
			error_label.text = "Login successful but failed to fetch user info."
			error_label.visible = true
	else:
		DebugLogger.log("Login failed: " + result.problem)
		error_label.text = result.problem
		error_label.visible = true



func _attempt_auto_login() -> void:	
	login_panel.visible = false
	DebugLogger.log("Attempting automatic login from saved token...")
	
	var success = await AuthManager.attempt_auto_login()
	
	if success:
		DebugLogger.log("Auto-login successful, fetching user info...")
		
		var user_info_response = await UserAPI.get_user_game_info()
		
		if user_info_response.success:
			var user_info: UserModels.ReadUserGameInfoResponse = user_info_response.data
			_successfully_log_in(user_info.user_name, user_info.balance)
		else:
			DebugLogger.log("Failed to fetch user info: " + user_info_response.problem.title)
			login_panel.visible = true
	else:
		DebugLogger.log("Auto-login failed, showing login screen")
		login_panel.visible = true


func _successfully_log_in(username: String, balance: int) -> void:
	ClientNetworkGlobals.username = username
	ClientNetworkGlobals.balance = balance

	NetworkHandler.start_client()
	get_tree().change_scene_to_file("res://scenes/levels/hub.tscn")
