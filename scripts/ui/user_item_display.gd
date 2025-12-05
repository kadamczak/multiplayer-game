extends Panel

@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var type_label = $MarginContainer/VBoxContainer/TypeLabel
@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var offer_label = $MarginContainer/VBoxContainer/OfferLabel


func setup(user_item: ItemModels.ReadUserItemResponse) -> void:
	name_label.text = user_item.item.name
	type_label.text = ItemModels.type_string_to_display(user_item.item.type)
	description_label.text = user_item.item.description
	
	# Display offer status if item has an active offer
	if user_item.activeOfferId != null:
		offer_label.text = "Awaiting trade for %d Gems" % user_item.activeOfferPrice
		offer_label.visible = true
	else:
		offer_label.visible = false
