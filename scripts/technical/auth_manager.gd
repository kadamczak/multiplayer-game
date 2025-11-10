extends Node

signal token_refreshed(access_token: String)
signal token_refresh_failed()

var access_token: String = ""
var refresh_token: String = ""
var stay_logged_in: bool = true

var _instance_name: String = ""
var _is_refreshing: bool = false


func _ready() -> void:
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--name="):
			_instance_name = arg.get_slice("=", 1)
			break


func has_access_token() -> bool:
	return not access_token.is_empty()


func get_auth_header() -> String:
	return "Bearer " + access_token


func set_stay_logged_in(stay_logged: bool) -> void:
	stay_logged_in = stay_logged


func store_tokens(access: String, refresh: String) -> void:
	access_token = access
	refresh_token = refresh

	if stay_logged_in:
		_save_refresh_token_to_file(refresh)


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


func _save_refresh_token_to_file(token: String) -> void:
	var filename = _get_refresh_token_filename()
	var file = FileAccess.open(filename, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to save refresh token to file: " + filename + " (Error: " + str(FileAccess.get_open_error()) + ")")
		return
	
	file.store_string(token)
	file.close()
	
	DebugLogger.log("Refresh token saved to: " + filename)


func _get_refresh_token_filename() -> String:
	var base_name = "auth_token"
	if not _instance_name.is_empty():
		base_name += "_" + _instance_name
	
	return "user://" + base_name + ".dat"


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



func clear_tokens() -> void:
	access_token = ""
	refresh_token = ""
	
	var filename = _get_refresh_token_filename()
	if FileAccess.file_exists(filename):
		DirAccess.remove_absolute(filename)
		DebugLogger.log("Token file deleted: " + filename)
	
	DebugLogger.log("All tokens cleared")


func refresh_access_token() -> bool:
	if refresh_token.is_empty():
		DebugLogger.log("No refresh token available")
		token_refresh_failed.emit()
		return false
	
	var response = await IdentityAPI.refresh(refresh_token)
	
	if not response.success:
		var problem: ApiResponse.ProblemDetails = response.problem
		DebugLogger.log("Token refresh failed with code: " + str(problem.status))
		DebugLogger.log("Response: " + problem.title)
		token_refresh_failed.emit()
		return false
	
	var token_response: UserModels.TokenResponse = response.data
	store_tokens(token_response.access_token, token_response.refresh_token)
	
	DebugLogger.log("Token refresh successful")
	token_refreshed.emit(token_response.access_token)
	return true

