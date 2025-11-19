class_name ItemModels

enum ItemType {
	CONSUMABLE,
	EQUIPPABLE_ON_HEAD,
	EQUIPPABLE_ON_BODY
}


static func string_to_item_type(type_str: String) -> ItemType:
	match type_str:
		"Consumable":
			return ItemType.CONSUMABLE
		"EquippableOnHead":
			return ItemType.EQUIPPABLE_ON_HEAD
		"EquippableOnBody":
			return ItemType.EQUIPPABLE_ON_BODY
		_:
			return ItemType.CONSUMABLE

static func item_type_to_display_string(item_type: ItemType) -> String:
	match item_type:
		ItemType.CONSUMABLE:
			return "Consumable"
		ItemType.EQUIPPABLE_ON_HEAD:
			return "Equippable on Head"
		ItemType.EQUIPPABLE_ON_BODY:
			return "Equippable on Body"
		_:
			return "Unknown"

static func type_string_to_display(type_str: String) -> String:
	match type_str:
		"Consumable":
			return "Consumable"
		"EquippableOnHead":
			return "Equippable on Head"
		"EquippableOnBody":
			return "Equippable on Body"
		_:
			return type_str


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