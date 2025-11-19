extends HBoxContainer

signal buy_pressed(offer_id: int, price: int)

var offer_id: int = -1
var price: int = 0

@onready var thumbnail_rect = $ThumbnailRect
@onready var item_name_label = $TopRow/VBoxContainer/HBoxContainer/ItemNameLabel
@onready var price_label = $TopRow/VBoxContainer/HBoxContainer/PriceLabel
@onready var buy_button = $TopRow/VBoxContainer/HBoxContainer/BuyButton
@onready var description_label = $TopRow/VBoxContainer/DescriptionLabel


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_button_pressed)


func setup(offer) -> void:
	offer_id = offer.id
	price = offer.price
	
	item_name_label.text = offer.item.name
	price_label.text = str(offer.price) + " gold"
	description_label.text = offer.item.description
	
	# Load thumbnail image if URL is provided
	if offer.item.thumbnailUrl and not offer.item.thumbnailUrl.is_empty():
		_load_thumbnail(offer.item.thumbnailUrl)


func _load_thumbnail(thumbnail_url: String) -> void:
	var full_url = ApiConfig.API_BASE_URL + thumbnail_url
	var texture = await ApiHelper.download_image(full_url)
	
	if texture != null:
		thumbnail_rect.texture = texture


func _on_buy_button_pressed() -> void:
	buy_pressed.emit(offer_id, price)
