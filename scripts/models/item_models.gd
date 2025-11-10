class_name ItemModels

class ReadItemResponse:
	var id: int
	var name: String
	var description: String
	
	func _init(data: Dictionary = {}) -> void:
		id = data.get("id")
		name = data.get("name")
		description = data.get("description")
	
	static func from_json(data: Dictionary) -> ReadItemResponse:
		return ReadItemResponse.new(data)