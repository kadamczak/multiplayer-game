class_name ApiResponse
# Generic API response wrapper
# Returns either:
#   { "success": true, "data": T }
# or
#   { "success": false, "problem": ProblemDetails }


# ASP.NET Core Problem Details response format
class ProblemDetails:
	var status: int
	var title: String
	
	# Optional fields
	var errors: Dictionary # Dictionary<String, Array<String>>
    
	var type: String
	var detail: String
	var instance: String
	
	func _init(data: Dictionary = {}):
		status = data.get("status", 0)
		title = data.get("title", "")
		errors = data.get("errors", {})
		type = data.get("type", "")
		detail = data.get("detail", "")
		instance = data.get("instance", "")
	
	static func from_json(data: Dictionary) -> ProblemDetails:
		return ProblemDetails.new(data)


static func is_success(response: Dictionary) -> bool:
	return response.get("success", false) == true

static func get_field_errors(problem: ProblemDetails) -> Dictionary:
	if problem == null or problem.errors.is_empty():
		return {}
	
	var field_errors: Dictionary = {}
	
	for field in problem.errors.keys():
		var messages: Array = problem.errors[field]
		var camel_case_field = _pascal_to_camel_case(field)
		field_errors[camel_case_field] = "\n".join(messages)
	
	return field_errors

static func _pascal_to_camel_case(pascal: String) -> String:
	if pascal.is_empty():
		return ""
	return pascal[0].to_lower() + pascal.substr(1)
