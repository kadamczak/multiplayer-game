extends Panel

signal back_pressed()

const USER_ITEM_DISPLAY = preload("res://scenes/ui/main_menu_ui/user_item_display.tscn")

enum EquipmentSlot { HEAD_ITEM, BODY_ITEM }

const CUSTOMIZATION_PARTS = {
	EquipmentSlot.HEAD_ITEM: "Head_Item",
	EquipmentSlot.BODY_ITEM: "Body_Item"
}

@onready var items_container = $MarginContainer/VBoxContainer/ContentHBox/ItemsScrollContainer/ItemsContainer
@onready var back_button = $MarginContainer/VBoxContainer/BackButton

@onready var head_slot = $MarginContainer/VBoxContainer/ContentHBox/EquipmentPanel/HeadSlot
@onready var head_slot_label = $MarginContainer/VBoxContainer/ContentHBox/EquipmentPanel/HeadSlot/MarginContainer/VBoxContainer/ItemLabel

@onready var body_slot = $MarginContainer/VBoxContainer/ContentHBox/EquipmentPanel/BodySlot
@onready var body_slot_label = $MarginContainer/VBoxContainer/ContentHBox/EquipmentPanel/BodySlot/MarginContainer/VBoxContainer/ItemLabel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	head_slot.gui_input.connect(_on_head_slot_gui_input)
	body_slot.gui_input.connect(_on_body_slot_gui_input)
	back_button.focus_mode = Control.FOCUS_ALL
	hide()


func show_panel() -> void:
	_clear_items()
	_update_equipment_slots()
	_display_items()
	show()
	back_button.call_deferred("grab_focus")


func _on_back_pressed() -> void:
	back_pressed.emit()


func _clear_items() -> void:
	for child in items_container.get_children():
		child.queue_free()


func _update_equipment_slots() -> void:
	_update_slot_label(EquipmentSlot.HEAD_ITEM, head_slot_label)
	_update_slot_label(EquipmentSlot.BODY_ITEM, body_slot_label)


func _display_items() -> void:
	if ClientNetworkGlobals.user_items.is_empty():
		var no_items_label = Label.new()
		no_items_label.text = "No items found"
		no_items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_items_label.add_theme_font_size_override("font_size", 18)
		items_container.add_child(no_items_label)
	else:
		for user_item in ClientNetworkGlobals.user_items:
			var item_display = USER_ITEM_DISPLAY.instantiate()
			items_container.add_child(item_display)
			item_display.setup(user_item)
			
			item_display.set_equipped(_is_equipped(user_item))
			item_display.item_right_clicked.connect(_on_item_right_clicked.bind(user_item))


func _is_equipped(user_item: ItemModels.ReadUserItemResponse) -> bool:
	return (
		user_item.id == ClientNetworkGlobals.customization.equipped_head_user_item_id or
		user_item.id == ClientNetworkGlobals.customization.equipped_body_user_item_id
	)


func _update_slot_label(slot: EquipmentSlot, label: Label) -> void:
	var equipped_user_item_id = _get_equipped_item_id(slot)
	var user_item = ClientNetworkGlobals.find_user_item_by_id(equipped_user_item_id)
	
	if user_item:
		label.text = user_item.item.name
	else:
		label.text = "Empty"


func _get_equipped_item_id(slot: EquipmentSlot) -> Variant:
	match slot:
		EquipmentSlot.HEAD_ITEM:
			return ClientNetworkGlobals.customization.equipped_head_user_item_id
		EquipmentSlot.BODY_ITEM:
			return ClientNetworkGlobals.customization.equipped_body_user_item_id
		_:
			return null


func _set_equipped_item_id(slot: EquipmentSlot, item_id: Variant) -> void:
	match slot:
		EquipmentSlot.HEAD_ITEM:
			ClientNetworkGlobals.customization.equipped_head_user_item_id = item_id
		EquipmentSlot.BODY_ITEM:
			ClientNetworkGlobals.customization.equipped_body_user_item_id = item_id


func _on_item_right_clicked(user_item: ItemModels.ReadUserItemResponse) -> void:
	var slot = _get_slot_for_item_type(user_item.item.type)
	if slot != null:
		_equip_item(user_item.id, slot)


func _get_slot_for_item_type(item_type: String) -> Variant:
	match item_type:
		"EquippableOnHead":
			return EquipmentSlot.HEAD_ITEM
		"EquippableOnBody":
			return EquipmentSlot.BODY_ITEM
		_:
			return null


func _on_head_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_unequip_item(EquipmentSlot.HEAD_ITEM)


func _on_body_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_unequip_item(EquipmentSlot.BODY_ITEM)


func _equip_item(user_item_id: String, slot: EquipmentSlot) -> void:
	var user_item = ClientNetworkGlobals.find_user_item_by_id(user_item_id)
	if not user_item:
		DebugLogger.log("Failed to find user item %s" % user_item_id)
		return
	
	_set_equipped_item_id(slot, user_item_id)
	
	var request = UserModels.UpdateUserEquippedItemsRequest.new(
		ClientNetworkGlobals.customization.equipped_head_user_item_id,
		ClientNetworkGlobals.customization.equipped_body_user_item_id
	)
	
	var result = await UserAPI.update_user_equipped_items(request)
	
	if not result.success:
		DebugLogger.log("Failed to equip item: %s" % result.error_message)
		return
	
	var item_id = user_item.item.id
	_apply_item_to_player(slot, item_id)
	_update_equipment_slots()
	_refresh_items_list()
	_send_equipped_items_packet()


func _unequip_item(slot: EquipmentSlot) -> void:
	_set_equipped_item_id(slot, null)
	
	var request = UserModels.UpdateUserEquippedItemsRequest.new(
		ClientNetworkGlobals.customization.equipped_head_user_item_id,
		ClientNetworkGlobals.customization.equipped_body_user_item_id
	)
	
	var result = await UserAPI.update_user_equipped_items(request)
	
	if not result.success:
		DebugLogger.log("Failed to unequip item: %s" % result.error_message)
		return
	
	_apply_item_to_player(slot, 0)
	_update_equipment_slots()
	_refresh_items_list()
	_send_equipped_items_packet()


func _apply_item_to_player(slot: EquipmentSlot, item_id: int) -> void:
	var player_customization = _get_local_player_customization()
	if not player_customization:
		DebugLogger.log("Failed to get player customization")
		return
	
	var part_name = CUSTOMIZATION_PARTS[slot]
	var part = player_customization.active_player_customization.get(part_name)
	if part:
		part.line_type = item_id
		player_customization.apply_customization(part)


func _get_local_player_customization() -> PlayerCustomization:
	var local_player = ClientNetworkGlobals.get_local_player(get_tree().current_scene)

	var player_customization = local_player.get_node_or_null("PlayerCustomization")
	if player_customization:
		return player_customization as PlayerCustomization
	
	return null


func _refresh_items_list() -> void:
	_clear_items()
	_display_items()


func _send_equipped_items_packet() -> void:
	var head_item_id = ClientNetworkGlobals.find_item_id_by_user_item_id(
		ClientNetworkGlobals.customization.equipped_head_user_item_id
	)
	var body_item_id = ClientNetworkGlobals.find_item_id_by_user_item_id(
		ClientNetworkGlobals.customization.equipped_body_user_item_id
	)
	
	var packet = PlayerEquippedItems.create(
		ClientNetworkGlobals.id,
		head_item_id,
		body_item_id
	)
	
	ClientNetworkGlobals.player_equipped_items[ClientNetworkGlobals.id] = packet
	packet.send(NetworkHandler.server_peer)
	
	DebugLogger.log("Sent equipped items update to other players")
