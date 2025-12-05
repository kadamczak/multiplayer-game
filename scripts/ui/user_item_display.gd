extends Panel

signal item_right_clicked()

@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var type_label = $MarginContainer/VBoxContainer/TypeLabel
@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var offer_label = $MarginContainer/VBoxContainer/OfferLabel


func _ready() -> void:
	gui_input.connect(_on_gui_input)


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


func set_equipped(is_equipped: bool) -> void:
	if is_equipped:
		name_label.text = "✓ " + name_label.text if not name_label.text.begins_with("✓") else name_label.text
	else:
		name_label.text = name_label.text.replace("✓ ", "")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			item_right_clicked.emit()
