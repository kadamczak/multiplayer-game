extends Node

const BASE_URL = "https://localhost:7110/v1"

# Helper function to parse error responses
static func parse_problem_details(response_code: int,
                                  response_headers: PackedStringArray,
                                  response_body: PackedByteArray) -> ApiResponse.ProblemDetails:
	var content_type = ""
	for header in response_headers:
		if header.to_lower().begins_with("content-type:"):
			content_type = header.split(":", true, 1)[1].strip_edges()
			break
	
	if content_type.contains("application/json") or content_type.contains("application/problem+json"):
		var json = JSON.parse_string(response_body.get_string_from_utf8())
		if json != null:
			return ApiResponse.ProblemDetails.from_json({
				"status": response_code,
				"title": json.get("title", "Request failed"),
				"errors": json.get("errors", {}),
				"type": json.get("type", ""),
				"detail": json.get("detail", ""),
				"instance": json.get("instance", "")
			})
	
	# Fallback for non-JSON responses
	var text = response_body.get_string_from_utf8()
	return ApiResponse.ProblemDetails.new({
		"title": text if not text.is_empty() else "Request failed",
		"status": response_code
	})


# Generic API request wrapper
# Returns ApiResponse format: { "success": true, "data": T } or { "success": false, "problem": ProblemDetails }
static func api_request(url: String,
                        method: HTTPClient.Method,
                        body: String = "",
                        headers: Array = []) -> Dictionary:
	var http_request = HTTPRequest.new()
	http_request.set_tls_options(TLSOptions.client_unsafe())
	
	var scene_root = Engine.get_main_loop().root
	scene_root.add_child(http_request)
	
	var default_headers = [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	
	# Merge with provided headers
	for header in headers:
		default_headers.append(header)
	
	var error = http_request.request(url, default_headers, method, body)
	
	if error != OK:
		http_request.queue_free()
		return {
			"success": false,
			"problem": ApiResponse.ProblemDetails.new({
				"title": "Request failed with error: " + str(error),
				"status": 0,
				"detail": "Error code: " + str(error)
			})
		}
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result = response[0]
	var response_code = response[1]
	var response_headers = response[2]
	var response_body = response[3]
	
	# Handle network errors
	if result != OK:
		return {
			"success": false,
			"problem": ApiResponse.ProblemDetails.new({
				"title": "Unexpected error. Please try again.",
				"status": 0,
				"detail": "Network error code: " + str(result)
			})
		}
	
	# Success responses (2xx)
	if response_code >= 200 and response_code < 300:
		var content_type = ""
		for header in response_headers:
			if header.to_lower().begins_with("content-type:"):
				content_type = header.split(":", true, 1)[1].strip_edges()
				break
		
		if content_type.contains("application/json"):
			var json = JSON.parse_string(response_body.get_string_from_utf8())
			if json != null:
				return { "success": true, "data": json }
		
		# For void responses (no content)
		return { "success": true, "data": null }
	
	# Error responses
	var problem = parse_problem_details(response_code, response_headers, response_body)
	return { "success": false, "problem": problem }



## Make an authenticated HTTP request with automatic token refresh on 401
func make_authenticated_request(url: String, method: HTTPClient.Method, body: String = "", additional_headers: Array = []) -> Array:
	if not AuthManager.has_access_token():
		DebugLogger.log("No access token available")
		AuthManager.token_refresh_failed.emit()
		return [FAILED, 0, [], PackedByteArray()]
	
	var http = HTTPRequest.new()
	add_child(http)
	http.set_tls_options(TLSOptions.client_unsafe())
	
	var headers = [
		"Authorization: " + AuthManager.get_auth_header(),
		"Content-Type: application/json",
		"Accept: application/json",
	]
	
	for header in additional_headers:
		headers.append(header)
	
	var error = http.request(url, headers, method, body)
	if error != OK:
		DebugLogger.log("Request failed with error: " + str(error))
		http.queue_free()
		return [error, 0, [], PackedByteArray()]
	
	var response = await http.request_completed
	http.queue_free()
	
	var response_code = response[1]
	
	# If 401, try to refresh token and retry once
	if response_code == 401:
		DebugLogger.log("Received 401, attempting to refresh token and retry...")
		
		if AuthManager._is_refreshing:
			DebugLogger.log("Already refreshing, skipping retry")
			return response
		
		AuthManager._is_refreshing = true
		var refreshed = await AuthManager.refresh_access_token()
		AuthManager._is_refreshing = false
		
		if not refreshed:
			DebugLogger.log("Token refresh failed, cannot retry request")
			AuthManager.token_refresh_failed.emit()
			return response
		
		# Retry the original request with new token
		DebugLogger.log("Token refreshed, retrying original request...")
		var retry_http = HTTPRequest.new()
		add_child(retry_http)
		retry_http.set_tls_options(TLSOptions.client_unsafe())
		headers[0] = "Authorization: " + AuthManager.get_auth_header()
		
		error = retry_http.request(url, headers, method, body)
		if error != OK:
			DebugLogger.log("Retry request failed with error: " + str(error))
			retry_http.queue_free()
			return [error, 0, [], PackedByteArray()]
		
		var retry_response = await retry_http.request_completed
		retry_http.queue_free()
		response = retry_response
	

	return response
