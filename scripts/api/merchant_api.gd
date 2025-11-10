class_name MerchantAPI

static func get_merchant_offers(merchant_id: int) -> Dictionary:
	return await ApiHelper.authenticated_request_with_refresh(
		ApiConfig.API_BASE_URL + "/v1/merchants/" + str(merchant_id) + "/offers",
		HTTPClient.METHOD_GET,
		[],
		"",
        MerchantModels.ReadMerchantOfferResponse.from_json_array
	)