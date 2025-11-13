extends VBoxContainer

signal buy_pressed(offer_id: int, price: int)

var offer_id: int = -1
var price: int = 0

@onready var item_name_label = $TopRow/ItemNameLabel
@onready var price_label = $TopRow/PriceLabel
@onready var buy_button = $TopRow/BuyButton
@onready var description_label = $DescriptionLabel


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_button_pressed)


func setup(offer) -> void:
	offer_id = offer.id
	price = offer.price
	
	item_name_label.text = offer.item.name
	price_label.text = str(offer.price) + " gold"
	description_label.text = offer.item.description


func _on_buy_button_pressed() -> void:
	buy_pressed.emit(offer_id, price)
