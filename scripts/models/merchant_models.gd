class_name MerchantModels

class ReadMerchantOfferResponse:
	var id: int
	var item: ItemModels.ReadItemResponse
	var price: int
	
	func _init(data: Dictionary = {}) -> void:
		id = data.get("id")
		price = data.get("price")
		
		var item_data = data.get("item")
		if item_data == null:
			push_error("ReadMerchantOfferResponse: 'item' is required but was null")
			item = ItemModels.ReadItemResponse.new()
		elif item_data is Dictionary:
			item = ItemModels.ReadItemResponse.from_json(item_data)
		else:
			item = ItemModels.ReadItemResponse.new()
	
	static func from_json(data: Dictionary) -> ReadMerchantOfferResponse:
		return ReadMerchantOfferResponse.new(data)
	
	static func from_json_array(data: Array) -> Array[ReadMerchantOfferResponse]:
		var offers: Array[ReadMerchantOfferResponse] = []
		for offer_data in data:
			if offer_data is Dictionary:
				offers.append(ReadMerchantOfferResponse.from_json(offer_data))
		return offers
