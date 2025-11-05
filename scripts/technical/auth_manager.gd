# extends Node
# ## AuthManager - Handles authentication tokens, automatic refresh, and persistent storage

# signal token_refreshed(access_token: String)
# signal token_refresh_failed()

# var access_token: String = ""
# var refresh_token: String = ""
# var token_expiry_time: int = 0  # Unix timestamp when token expires

# const TOKEN_REFRESH_BUFFER: int = 60  # Refresh 60 seconds before expiry
# const AUTH_API_BASE: String = "https://localhost:7110/v1/identity"

# var _refresh_timer: Timer
# var _instance_name: String = ""
 

# func _ready() -> void:
# 	# Get instance name from command line
# 	var args := OS.get_cmdline_args()
# 	for arg in args:
# 		if arg.begins_with("--name="):
# 			_instance_name = arg.get_slice("=", 1)
# 			break
	
# 	# Create refresh timer
# 	_refresh_timer = Timer.new()
# 	_refresh_timer.one_shot = true
# 	_refresh_timer.timeout.connect(_on_refresh_timer_timeout)
# 	add_child(_refresh_timer)
	
# 	DebugLogger.log("AuthManager initialized for instance: " + (_instance_name if not _instance_name.is_empty() else "default"))


# ## Store tokens in memory and persist refresh token to disk
# func store_tokens(access: String, refresh: String, expires_in: int) -> void:
# 	access_token = access
# 	refresh_token = refresh
	
# 	# Calculate expiry time
# 	var current_time = Time.get_unix_time_from_system()
# 	token_expiry_time = int(current_time) + expires_in
	
# 	DebugLogger.log("Tokens stored. Expires in " + str(expires_in) + " seconds")
	
# 	# Save refresh token to file
# 	_save_refresh_token_to_file(refresh)
	
# 	# Schedule automatic refresh
# 	_schedule_token_refresh(expires_in)


# ## Save refresh token to secure file
# func _save_refresh_token_to_file(token: String) -> void:
# 	var filename = _get_token_filename()
# 	var file = FileAccess.open(filename, FileAccess.WRITE)
	
# 	if file == null:
# 		push_error("Failed to save refresh token to file: " + filename + " (Error: " + str(FileAccess.get_open_error()) + ")")
# 		return
	
# 	file.store_string(token)
# 	file.close()
	
# 	DebugLogger.log("Refresh token saved to: " + filename)


# ## Load refresh token from secure file
# func load_refresh_token_from_file() -> String:
# 	var filename = _get_token_filename()
	
# 	if not FileAccess.file_exists(filename):
# 		DebugLogger.log("No saved refresh token found at: " + filename)
# 		return ""
	
# 	var file = FileAccess.open(filename, FileAccess.READ)
# 	if file == null:
# 		push_error("Failed to load refresh token from file: " + filename)
# 		return ""
	
# 	var token = file.get_as_text().strip_edges()
# 	file.close()
	
# 	DebugLogger.log("Refresh token loaded from: " + filename)
# 	return token


# ## Get the filename for storing the refresh token
# func _get_token_filename() -> String:
# 	var base_name = "auth_token"
# 	if not _instance_name.is_empty():
# 		base_name += "_" + _instance_name
	
# 	# Store in user data directory
# 	return "user://" + base_name + ".dat"


# ## Clear all tokens from memory and delete file
# func clear_tokens() -> void:
# 	access_token = ""
# 	refresh_token = ""
# 	token_expiry_time = 0
	
# 	_refresh_timer.stop()
	
# 	var filename = _get_token_filename()
# 	if FileAccess.file_exists(filename):
# 		DirAccess.remove_absolute(filename)
# 		DebugLogger.log("Token file deleted: " + filename)
	
# 	DebugLogger.log("All tokens cleared")


# ## Check if we have a valid access token
# func has_valid_token() -> bool:
# 	if access_token.is_empty():
# 		return false
	
# 	var current_time = Time.get_unix_time_from_system()
# 	return int(current_time) < token_expiry_time


# ## Get authorization header for HTTP requests
# func get_auth_header() -> String:
# 	return "Bearer " + access_token


# ## Schedule automatic token refresh
# func _schedule_token_refresh(expires_in: int) -> void:
# 	# Schedule refresh before token expires
# 	var refresh_in = max(expires_in - TOKEN_REFRESH_BUFFER, 30)  # At least 30 seconds
# 	_refresh_timer.start(refresh_in)
	
# 	DebugLogger.log("Token refresh scheduled in " + str(refresh_in) + " seconds")


# ## Timer callback to refresh token
# func _on_refresh_timer_timeout() -> void:
# 	DebugLogger.log("Attempting automatic token refresh...")
# 	await refresh_access_token()


# ## Refresh the access token using the refresh token
# func refresh_access_token() -> bool:
# 	if refresh_token.is_empty():
# 		DebugLogger.log("No refresh token available")
# 		token_refresh_failed.emit()
# 		return false
	
# 	var http = HTTPRequest.new()
# 	add_child(http)
	
# 	var body = JSON.stringify({
# 		"refreshToken": refresh_token
# 	})
	
# 	var headers = [
# 		"Content-Type: application/json",
# 		"Accept: application/json"
# 	]
	
# 	var error = http.request(
# 		AUTH_API_BASE + "/refresh",
# 		headers,
# 		HTTPClient.METHOD_POST,
# 		body
# 	)
	
# 	if error != OK:
# 		DebugLogger.log("Token refresh request failed with error: " + str(error))
# 		http.queue_free()
# 		token_refresh_failed.emit()
# 		return false
	
# 	# Wait for response
# 	var response = await http.request_completed
# 	http.queue_free()
	
# 	var _result = response[0]
# 	var response_code = response[1]
# 	var response_body = response[3]
	
# 	if response_code == 200:
# 		var json = JSON.parse_string(response_body.get_string_from_utf8())
		
# 		if json != null and json.has("accessToken") and json.has("refreshToken"):
# 			var new_access = json.get("accessToken", "")
# 			var new_refresh = json.get("refreshToken", "")
# 			var expires_in = json.get("expiresIn", 3600)
			
# 			store_tokens(new_access, new_refresh, expires_in)
# 			DebugLogger.log("Token refresh successful")
# 			token_refreshed.emit(new_access)
# 			return true
# 		else:
# 			DebugLogger.log("Token refresh response missing tokens")
# 			token_refresh_failed.emit()
# 			return false
# 	else:
# 		DebugLogger.log("Token refresh failed with code: " + str(response_code))
# 		DebugLogger.log("Response: " + response_body.get_string_from_utf8())
		
# 		# Clear invalid tokens
# 		clear_tokens()
# 		token_refresh_failed.emit()
# 		return false


# ## Attempt automatic login using saved refresh token
# func attempt_auto_login() -> bool:
# 	DebugLogger.log("Attempting automatic login...")
	
# 	var saved_refresh = load_refresh_token_from_file()
# 	if saved_refresh.is_empty():
# 		DebugLogger.log("No saved refresh token found")
# 		return false
	
# 	# Store the refresh token temporarily
# 	refresh_token = saved_refresh
	
# 	# Try to refresh and get new access token
# 	var success = await refresh_access_token()
	
# 	if not success:
# 		DebugLogger.log("Automatic login failed")
# 		return false
	
# 	DebugLogger.log("Automatic login successful")
# 	return true


# ## Make an authenticated HTTP request with automatic token refresh on 401
# func make_authenticated_request(http_request: HTTPRequest, url: String, method: HTTPClient.Method, body: String = "", additional_headers: Array = []) -> void:
# 	# Check if token needs refresh
# 	if not has_valid_token():
# 		DebugLogger.log("Token expired or missing, attempting refresh...")
# 		var refreshed = await refresh_access_token()
# 		if not refreshed:
# 			DebugLogger.log("Failed to refresh token before request")
# 			token_refresh_failed.emit()
# 			return
	
# 	var headers = [
# 		"Authorization: " + get_auth_header(),
# 		"Content-Type: application/json",
# 		"Accept: application/json"
# 	]
	
# 	# Add any additional headers
# 	for header in additional_headers:
# 		headers.append(header)
	
# 	http_request.request(url, headers, method, body)
