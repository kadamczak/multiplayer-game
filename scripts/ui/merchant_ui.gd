extends CanvasLayer

signal talk_clicked()
signal trade_clicked()
signal back_from_trade_clicked()
signal buy_clicked(offer_id: int, price: int)

@onready var talk_panel = $TalkPanel
@onready var dialogue_label = $TalkPanel/HBoxContainer/RightSide/DialogueLabel
@onready var talk_button = $TalkPanel/HBoxContainer/RightSide/ButtonContainer/TalkButton
@onready var trade_button = $TalkPanel/HBoxContainer/RightSide/ButtonContainer/TradeButton

@onready var trade_panel = $TradePanel
@onready var offers_container = $TradePanel/MarginContainer/VBoxContainer/OffersScrollContainer/OffersContainer
@onready var back_button = $TradePanel/MarginContainer/VBoxContainer/BackButton
@onready var error_label = $TradePanel/MarginContainer/VBoxContainer/ErrorLabel


func _ready() -> void:
	hide_ui()
	talk_button.pressed.connect(_on_talk_pressed)
	trade_button.pressed.connect(_on_trade_pressed)
	back_button.pressed.connect(_on_back_from_trade_pressed)
	talk_button.focus_mode = Control.FOCUS_ALL
	back_button.focus_mode = Control.FOCUS_ALL


func is_ui_visible() -> bool:
	return talk_panel.visible or trade_panel.visible


func show_talk_panel(text: String, button_selected: String) -> void:
	ClientNetworkGlobals.is_movement_blocking_ui_active = true
	dialogue_label.text = text
	talk_panel.visible = true
	trade_panel.visible = false

	if button_selected == "Talk":
		talk_button.call_deferred("grab_focus")
	elif button_selected == "Trade":
		trade_button.call_deferred("grab_focus")


func show_trade_panel() -> void:
	clear_error()
	_clear_offers()
	talk_panel.visible = false
	trade_panel.visible = true


func hide_ui() -> void:
	talk_panel.visible = false
	trade_panel.visible = false
	ClientNetworkGlobals.is_movement_blocking_ui_active = false


func hide_trade_panel() -> void:
	trade_panel.visible = false


func display_offers(offers: Array) -> void:
	_clear_offers()
	var previous_button: Button = null
	
	for i in range(offers.size()):
		var offer = offers[i]
		var offer_item = _create_offer_item(offer)
		offers_container.add_child(offer_item)
		
		var buy_button = offer_item.get_node("TopRow/BuyButton")
		buy_button.pressed.connect(_on_buy_button_pressed.bind(offer.id, offer.price))
		
		if previous_button:
			_setup_focus_navigation(previous_button, buy_button)		
			
		previous_button = buy_button
		
		# Set focus for first buy button
		if i == 0:
			buy_button.call_deferred("grab_focus")
	
	# Connect last buy button to back button
	if previous_button:
		_setup_focus_navigation(previous_button, back_button)


func _setup_focus_navigation(previous_button: Button, next_button: Button):
	previous_button.focus_neighbor_bottom = next_button.get_path()
	next_button.focus_neighbor_top = previous_button.get_path()


func _clear_offers() -> void:
	for child in offers_container.get_children():
		child.queue_free()


func _create_offer_item(offer) -> Control:
	var item_container = VBoxContainer.new()
	item_container.custom_minimum_size = Vector2(0, 60)
	
	# Top row: name and price
	var top_row = HBoxContainer.new()
	top_row.name = "TopRow"
	
	var item_name = Label.new()
	item_name.text = offer.item.name
	item_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_name.add_theme_font_size_override("font_size", 24)
	item_name.add_theme_color_override("font_color", Color(1, 1, 1))
	
	var price_label = Label.new()
	price_label.text = str(offer.price) + " gold"
	price_label.add_theme_font_size_override("font_size", 20)
	price_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	
	var buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(80, 40)
	buy_button.focus_mode = Control.FOCUS_ALL
	
	top_row.add_child(item_name)
	top_row.add_child(price_label)
	top_row.add_child(buy_button)
	
	# Description row
	var description_label = Label.new()
	description_label.text = offer.item.description
	description_label.add_theme_font_size_override("font_size", 16)
	description_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	item_container.add_child(top_row)
	item_container.add_child(description_label)
	
	return item_container


func show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true


func clear_error() -> void:
	error_label.text = ""
	error_label.visible = false


func _on_talk_pressed() -> void:
	talk_clicked.emit()


func _on_trade_pressed() -> void:
	trade_clicked.emit()


func _on_back_from_trade_pressed() -> void:
	back_from_trade_clicked.emit()


func _on_buy_button_pressed(offer_id: int, price: int) -> void:
	buy_clicked.emit(offer_id, price)
