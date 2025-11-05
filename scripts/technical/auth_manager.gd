extends Node

signal token_refreshed(access_token: String)
signal token_refresh_failed()

var access_token: String = ""
var refresh_token: String = ""
var stay_logged_in: bool = true

const AUTH_API_BASE: String = "https://localhost:7110/v1/identity"
var _instance_name: String = ""
var _is_refreshing: bool = false


func _ready() -> void:
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--name="):
			_instance_name = arg.get_slice("=", 1)
			break


## Store tokens in memory and persist refresh token to disk if stay_logged_in is true
func store_tokens(access: String, refresh: String, stay_logged: bool) -> void:
	access_token = access
	refresh_token = refresh
	stay_logged = stay_logged

	if stay_logged:
		_save_refresh_token_to_file(refresh)


func _save_refresh_token_to_file(token: String) -> void:
	var filename = _get_refresh_token_filename()
	var file = FileAccess.open(filename, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to save refresh token to file: " + filename + " (Error: " + str(FileAccess.get_open_error()) + ")")
		return
	
	file.store_string(token)
	file.close()
	
	DebugLogger.log("Refresh token saved to: " + filename)


func load_refresh_token_from_file() -> String:
	var filename = _get_refresh_token_filename()
	
	if not FileAccess.file_exists(filename):
		DebugLogger.log("No saved refresh token found at: " + filename)
		return ""
	
	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		push_error("Failed to load refresh token from file: " + filename)
		return ""
	
	var token = file.get_as_text().strip_edges()
	file.close()
	
	DebugLogger.log("Refresh token loaded from: " + filename)
	return token


func _get_refresh_token_filename() -> String:
	var base_name = "auth_token"
	if not _instance_name.is_empty():
		base_name += "_" + _instance_name
	
	return "user://" + base_name + ".dat"


func clear_tokens() -> void:
	access_token = ""
	refresh_token = ""
	
	var filename = _get_refresh_token_filename()
	if FileAccess.file_exists(filename):
		DirAccess.remove_absolute(filename)
		DebugLogger.log("Token file deleted: " + filename)
	
	DebugLogger.log("All tokens cleared")


func has_access_token() -> bool:
	return not access_token.is_empty()


func get_auth_header() -> String:
	return "Bearer " + access_token


func refresh_access_token() -> bool:
	if refresh_token.is_empty():
		DebugLogger.log("No refresh token available")
		token_refresh_failed.emit()
		return false
	
	var http = HTTPRequest.new()
	add_child(http)
	http.set_tls_options(TLSOptions.client_unsafe())
	
	var body = JSON.stringify(refresh_token)
	
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json",
		"X-Client-Type: Game"
	]
	
	var error = http.request(
		AUTH_API_BASE + "/refresh",
		headers,
		HTTPClient.METHOD_POST,
		body
	)
	
	if error != OK:
		DebugLogger.log("Token refresh request failed with error: " + str(error))
		http.queue_free()
		token_refresh_failed.emit()
		return false
	
	var response = await http.request_completed
	http.queue_free()
	
	var _result = response[0]
	var response_code = response[1]
	var response_body = response[3]
	
	if response_code == 200:
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		
		if json != null and json.has("accessToken") and json.has("refreshToken"):
			var new_access = json.get("accessToken", "")
			var new_refresh = json.get("refreshToken", "")
			
			access_token = new_access
			refresh_token = new_refresh
			
			if stay_logged_in:
				_save_refresh_token_to_file(new_refresh)
			
			DebugLogger.log("Token refresh successful")
			token_refreshed.emit(new_access)
			return true
		else:
			DebugLogger.log("Token refresh response missing tokens")
			token_refresh_failed.emit()
			return false
	else:
		DebugLogger.log("Token refresh failed with code: " + str(response_code))
		DebugLogger.log("Response: " + response_body.get_string_from_utf8())
		clear_tokens()
		token_refresh_failed.emit()
		return false


## Attempt automatic login using saved refresh token
func attempt_auto_login() -> bool:
	DebugLogger.log("Attempting automatic login...")
	
	var saved_refresh = load_refresh_token_from_file()
	if saved_refresh.is_empty():
		DebugLogger.log("No saved refresh token found")
		return false
	
	refresh_token = saved_refresh
	var success = await refresh_access_token()
	
	if not success:
		DebugLogger.log("Automatic login failed")
		return false
	
	DebugLogger.log("Automatic login successful")
	return true


## Make an authenticated HTTP request with automatic token refresh on 401
func make_authenticated_request(url: String, method: HTTPClient.Method, body: String = "", additional_headers: Array = []) -> Array:
	if not has_access_token():
		DebugLogger.log("No access token available")
		token_refresh_failed.emit()
		return [FAILED, 0, [], PackedByteArray()]
	
	var http = HTTPRequest.new()
	add_child(http)
	http.set_tls_options(TLSOptions.client_unsafe())
	
	var headers = [
		"Authorization: " + get_auth_header(),
		"Content-Type: application/json",
		"Accept: application/json",
	]
	
	# Add any additional headers
	for header in additional_headers:
		headers.append(header)
	
	var error = http.request(url, headers, method, body)
	if error != OK:
		DebugLogger.log("Request failed with error: " + str(error))
		http.queue_free()
		return [error, 0, [], PackedByteArray()]
	
	# Wait for response
	var response = await http.request_completed
	http.queue_free()
	
	var _result = response[0]
	var response_code = response[1]
	var _response_headers = response[2]
	var _response_body = response[3]
	
	# If 401, try to refresh token and retry once
	if response_code == 401:
		DebugLogger.log("Received 401, attempting to refresh token and retry...")
		
		# Prevent multiple simultaneous refresh attempts
		if _is_refreshing:
			DebugLogger.log("Already refreshing, skipping retry")
			return response
		
		_is_refreshing = true
		var refreshed = await refresh_access_token()
		_is_refreshing = false
		
		if not refreshed:
			DebugLogger.log("Token refresh failed, cannot retry request")
			token_refresh_failed.emit()
			return response
		
		# Retry the original request with new token
		DebugLogger.log("Token refreshed, retrying original request...")
		var retry_http = HTTPRequest.new()
		add_child(retry_http)
		retry_http.set_tls_options(TLSOptions.client_unsafe())
		
		# Update authorization header with new token
		headers[0] = "Authorization: " + get_auth_header()
		
		error = retry_http.request(url, headers, method, body)
		if error != OK:
			DebugLogger.log("Retry request failed with error: " + str(error))
			retry_http.queue_free()
			return [error, 0, [], PackedByteArray()]
		
		var retry_response = await retry_http.request_completed
		retry_http.queue_free()
		return retry_response
	
	return response
