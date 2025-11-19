extends Node

# Helper function to parse error responses
func parse_problem_details(response_code: int,
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
# If parse_callback is provided, it will be called with the JSON data to convert to a typed object
func api_request(url: String,
						method: HTTPClient.Method,
						additional_headers: Array = [],
						body: String = "",
						parse_callback: Callable = Callable()) -> Dictionary:
	var http_request = HTTPRequest.new()
	http_request.set_tls_options(TLSOptions.client_unsafe())
	add_child(http_request)
	
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	
	# Merge with provided headers
	for header in additional_headers:
		headers.append(header)
	
	var error = http_request.request(url, headers, method, body)

	
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
				# If parse_callback is provided, use it to convert JSON to typed object
				var data = json
				if parse_callback.is_valid():
					data = parse_callback.call(json)
				return { "success": true, "data": data }
		
		# For void responses (no content)
		return { "success": true, "data": null }
	
	# Error responses
	var problem = parse_problem_details(response_code, response_headers, response_body)
	return { "success": false, "problem": problem }


# Authenticated request wrapper - includes Authorization header
func authenticated_request(url: String,
								  access_token: String,
								  method: HTTPClient.Method,
								  additional_headers: Array = [],
								  body: String = "",
								  parse_callback: Callable = Callable()) -> Dictionary:
	var headers = additional_headers.duplicate()
	
	# Add Authorization header if token exists
	if not access_token.is_empty():
		headers.append("Authorization: Bearer " + access_token)
	
	return await api_request(url, method, headers, body, parse_callback)


# Authenticated request with automatic token refresh on 401
func authenticated_request_with_refresh(url: String,
											   method: HTTPClient.Method,
											   additional_headers: Array = [],
											   body: String = "",
											   parse_callback: Callable = Callable()) -> Dictionary:
	if not AuthManager.has_access_token():
		return {
			"success": false,
			"problem": ApiResponse.ProblemDetails.new({
				"title": "No access token available",
				"status": 401
			})
		}
	
	var access_token = AuthManager.access_token
	var response = await authenticated_request(url, access_token, method, additional_headers, body, parse_callback)
	
	# If unauthorized, attempt to refresh token and retry once
	if not response.success:
		var problem: ApiResponse.ProblemDetails = response.problem
		if problem.status == 401:
			if AuthManager._is_refreshing:
				return response
			
			AuthManager._is_refreshing = true
			var refreshed = await AuthManager.refresh_access_token()
			AuthManager._is_refreshing = false
			
			if refreshed:
				var new_token = AuthManager.access_token
				response = await authenticated_request(url, new_token, method, additional_headers, body, parse_callback)
			else:
				AuthManager.token_refresh_failed.emit()
				return response
	
	return response


# Image cache storage
# Key: URL, Value: { "texture": ImageTexture, "etag": String, "last_modified": String }
var _image_cache: Dictionary = {}


# Download image from URL with caching support
# Uses ETag and Last-Modified headers for cache validation
# Returns null if the download fails or the image cannot be loaded
func download_image(url: String) -> ImageTexture:
	var http_request = HTTPRequest.new()
	http_request.set_tls_options(TLSOptions.client_unsafe())
	add_child(http_request)
	
	var headers = []
	
	# Check if we have cached version and add conditional headers
	if _image_cache.has(url):
		var cache_entry = _image_cache[url]
		if cache_entry.has("etag") and not cache_entry.etag.is_empty():
			headers.append("If-None-Match: " + cache_entry.etag)
		if cache_entry.has("last_modified") and not cache_entry.last_modified.is_empty():
			headers.append("If-Modified-Since: " + cache_entry.last_modified)
	
	var error = http_request.request(url, headers)
	
	if error != OK:
		http_request.queue_free()
		return null
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result = response[0]
	var response_code = response[1]
	var response_headers = response[2]
	var response_body = response[3]
	
	if result != OK:
		return null
	
	# 304 Not Modified - return cached texture
	if response_code == 304:
		if _image_cache.has(url):
			return _image_cache[url].texture
		return null
	
	if response_code < 200 or response_code >= 300:
		return null
	
	# Try to load the image from the downloaded bytes
	var image = Image.new()
	var load_error = image.load_png_from_buffer(response_body)
	
	if load_error != OK:
		load_error = image.load_jpg_from_buffer(response_body)
	
	if load_error != OK:
		load_error = image.load_webp_from_buffer(response_body)
	
	if load_error != OK:
		return null
	
	# Create the texture
	var texture = ImageTexture.create_from_image(image)
	
	# Extract caching headers from response
	var etag = ""
	var last_modified = ""
	
	for header in response_headers:
		var header_lower = header.to_lower()
		if header_lower.begins_with("etag:"):
			etag = header.split(":", true, 1)[1].strip_edges()
		elif header_lower.begins_with("last-modified:"):
			last_modified = header.split(":", true, 1)[1].strip_edges()
	
	# Cache the texture with headers
	_image_cache[url] = {
		"texture": texture,
		"etag": etag,
		"last_modified": last_modified
	}
	
	return texture


func clear_image_cache() -> void:
	_image_cache.clear()
