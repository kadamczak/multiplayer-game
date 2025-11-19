class_name ItemModels

class ReadItemResponse:
	var id: int
	var name: String
	var description: String
	var type: String
	var thumbnailUrl: String
	
	func _init(data: Dictionary = {}) -> void:
		id = data.get("id")
		name = data.get("name")
		description = data.get("description")
		type = data.get("type")
		thumbnailUrl = data.get("thumbnailUrl")
	
	static func from_json(data: Dictionary) -> ReadItemResponse:
		return ReadItemResponse.new(data)


class ReadUserItemsSimplifiedResponse:
	var id: String
	var item: ReadItemResponse

	func _init(data: Dictionary = {}) -> void:
		id = data.get("id")

		var item_data = data.get("item")
		if item_data == null:
			item = ReadItemResponse.new()
		elif item_data is Dictionary:
			item = ReadItemResponse.from_json(item_data)
		else:
			item = ReadItemResponse.new()

	static func from_json(data: Dictionary) -> ReadUserItemsSimplifiedResponse:
		return ReadUserItemsSimplifiedResponse.new(data)