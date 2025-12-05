extends CanvasLayer

signal user_details_clicked()
signal logout_clicked()

const USER_ITEM_DISPLAY = preload("res://scenes/ui/main_menu_ui/user_item_display.tscn")

enum EquipmentSlot { HEAD_ITEM, BODY_ITEM }

const CUSTOMIZATION_PARTS = {
	EquipmentSlot.HEAD_ITEM: "Head_Item",
	EquipmentSlot.BODY_ITEM: "Body_Item"
}

@onready var menu_panel = $MenuPanel
@onready var user_details_button = $MenuPanel/MarginContainer/VBoxContainer/UserDetailsButton
@onready var items_button = $MenuPanel/MarginContainer/VBoxContainer/ItemsButton
@onready var logout_button = $MenuPanel/MarginContainer/VBoxContainer/LogoutButton
@onready var close_button = $MenuPanel/MarginContainer/VBoxContainer/CloseButton

@onready var user_details_panel = $UserDetailsPanel
@onready var username_label = $UserDetailsPanel/MarginContainer/VBoxContainer/UsernameLabel
@onready var balance_label = $UserDetailsPanel/MarginContainer/VBoxContainer/BalanceLabel
@onready var back_button = $UserDetailsPanel/MarginContainer/VBoxContainer/BackButton

@onready var items_panel = $ItemsPanel
@onready var items_container = $ItemsPanel/MarginContainer/VBoxContainer/ContentHBox/ItemsScrollContainer/ItemsContainer
@onready var items_back_button = $ItemsPanel/MarginContainer/VBoxContainer/BackButton
@onready var head_slot = $ItemsPanel/MarginContainer/VBoxContainer/ContentHBox/EquipmentPanel/HeadSlot
@onready var head_slot_label = $ItemsPanel/MarginContainer/VBoxContainer/ContentHBox/EquipmentPanel/HeadSlot/MarginContainer/VBoxContainer/ItemLabel
@onready var body_slot = $ItemsPanel/MarginContainer/VBoxContainer/ContentHBox/EquipmentPanel/BodySlot
@onready var body_slot_label = $ItemsPanel/MarginContainer/VBoxContainer/ContentHBox/EquipmentPanel/BodySlot/MarginContainer/VBoxContainer/ItemLabel


func _ready() -> void:
	hide_menu()
	hide_user_details()
	hide_items()
	
	user_details_button.pressed.connect(_on_user_details_pressed)
	items_button.pressed.connect(_on_items_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	close_button.pressed.connect(_on_close_pressed)
	back_button.pressed.connect(_on_back_pressed)
	items_back_button.pressed.connect(_on_items_back_pressed)
	
	# Set up focus
	user_details_button.focus_mode = Control.FOCUS_ALL
	items_button.focus_mode = Control.FOCUS_ALL
	logout_button.focus_mode = Control.FOCUS_ALL
	close_button.focus_mode = Control.FOCUS_ALL
	back_button.focus_mode = Control.FOCUS_ALL
	items_back_button.focus_mode = Control.FOCUS_ALL
	
	# Set up equipment slot mouse detection
	head_slot.gui_input.connect(_on_head_slot_gui_input)
	body_slot.gui_input.connect(_on_body_slot_gui_input)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_main_menu"):
		if items_panel.visible:
			hide_items()
			show_menu()
			get_viewport().set_input_as_handled()
		elif user_details_panel.visible:
			hide_user_details()
			show_menu()
			get_viewport().set_input_as_handled()
		elif menu_panel.visible:
			hide_menu()
			get_viewport().set_input_as_handled()
		elif not ClientNetworkGlobals.is_movement_blocking_ui_active:
			show_menu()
			get_viewport().set_input_as_handled()


func show_menu() -> void:
	ClientNetworkGlobals.is_movement_blocking_ui_active = true
	menu_panel.visible = true
	user_details_button.call_deferred("grab_focus")


func hide_menu() -> void:
	menu_panel.visible = false
	if not user_details_panel.visible and not items_panel.visible:
		ClientNetworkGlobals.is_movement_blocking_ui_active = false


func show_user_details() -> void:
	menu_panel.visible = false
	user_details_panel.visible = true
	
	# Update labels with current data
	username_label.text = "Username: " + ClientNetworkGlobals.username
	balance_label.text = "Balance: " + str(ClientNetworkGlobals.balance) + " Gems"
	
	back_button.call_deferred("grab_focus")


func hide_user_details() -> void:
	user_details_panel.visible = false


func _on_user_details_pressed() -> void:
	show_user_details()


func _on_logout_pressed() -> void:
	var tree = get_tree()

	if not AuthManager.refresh_token.is_empty():
		var result = await IdentityAPI.logout(AuthManager.refresh_token)
		if result.has("success") and result.success:
			DebugLogger.log("Logout API call successful")
		else:
			DebugLogger.log("Logout API call failed, clearing tokens anyway")
	
	AuthManager.clear_tokens()
	logout_clicked.emit()

	if NetworkHandler.connection != null:
		NetworkHandler.disconnect_client()
		DebugLogger.log("Disconnected from multiplayer server")

	ClientNetworkGlobals.reset()	

	if tree:
		tree.change_scene_to_file("res://scenes/levels/login_scene.tscn")


func _on_close_pressed() -> void:
	hide_menu()


func _on_back_pressed() -> void:
	hide_user_details()
	show_menu()


func show_items() -> void:
	menu_panel.visible = false
	items_panel.visible = true
	
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	
	# Update equipment slots
	_update_equipment_slots()
	
	# Display user items
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
			
			# Check if item is equipped
			var is_equipped = (
				user_item.id == ClientNetworkGlobals.customization.equipped_head_user_item_id or
				user_item.id == ClientNetworkGlobals.customization.equipped_body_user_item_id
			)
			item_display.set_equipped(is_equipped)
			
			item_display.item_right_clicked.connect(_on_item_right_clicked.bind(user_item))
	
	items_back_button.call_deferred("grab_focus")


func hide_items() -> void:
	items_panel.visible = false


func _on_items_pressed() -> void:
	show_items()


func _on_items_back_pressed() -> void:
	hide_items()
	show_menu()


func _update_equipment_slots() -> void:
	_update_slot_label(EquipmentSlot.HEAD_ITEM, head_slot_label)
	_update_slot_label(EquipmentSlot.BODY_ITEM, body_slot_label)


func _update_slot_label(slot: EquipmentSlot, label: Label) -> void:
	var equipped_id = _get_equipped_item_id(slot)
	var user_item = _find_user_item_by_id(equipped_id)
	
	if user_item:
		label.text = user_item.item.name
	else:
		label.text = "Empty"


func _get_equipped_item_id(slot: EquipmentSlot) -> String:
	match slot:
		EquipmentSlot.HEAD_ITEM:
			return ClientNetworkGlobals.customization.equipped_head_user_item_id
		EquipmentSlot.BODY_ITEM:
			return ClientNetworkGlobals.customization.equipped_body_user_item_id
		_:
			return ""


func _set_equipped_item_id(slot: EquipmentSlot, item_id: String) -> void:
	match slot:
		EquipmentSlot.HEAD_ITEM:
			ClientNetworkGlobals.customization.equipped_head_user_item_id = item_id
		EquipmentSlot.BODY_ITEM:
			ClientNetworkGlobals.customization.equipped_body_user_item_id = item_id


func _find_user_item_by_id(user_item_id: String) -> ItemModels.ReadUserItemResponse:
	if user_item_id.is_empty():
		return null
	
	return ClientNetworkGlobals.user_items.filter(func(item):
		return item.id == user_item_id).front()


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
	# TODO: Call API to equip item
	
	var user_item = _find_user_item_by_id(user_item_id)
	if not user_item:
		DebugLogger.log("Failed to find user item %s" % user_item_id)
		return
	
	var item_id = user_item.item.id
	_set_equipped_item_id(slot, user_item_id)
	_apply_item_to_player(slot, item_id)
	_update_equipment_slots()
	_refresh_items_list()


func _unequip_item(slot: EquipmentSlot) -> void:
	# TODO: Call API to unequip item
	
	_set_equipped_item_id(slot, "")
	_apply_item_to_player(slot, 0)
	_update_equipment_slots()
	_refresh_items_list()


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
	# Find the Players container in the current scene
	var scene_root = get_tree().current_scene
	if not scene_root:
		return null
	
	var player_container = scene_root.find_child("Players", false, false)
	if not player_container:
		return null
	
	# Get the local player using the client's ID
	var local_player = player_container.get_node_or_null(str(ClientNetworkGlobals.id))
	if not local_player:
		return null
	
	var player_customization = local_player.get_node_or_null("PlayerCustomization")
	if player_customization:
		return player_customization as PlayerCustomization
	
	return null


func _refresh_items_list() -> void:
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	
	# Redisplay items with updated equipped status
	if not ClientNetworkGlobals.user_items.is_empty():
		for user_item in ClientNetworkGlobals.user_items:
			var item_display = USER_ITEM_DISPLAY.instantiate()
			items_container.add_child(item_display)
			item_display.setup(user_item)
			
			# Check if item is equipped
			var is_equipped = (
				user_item.id == ClientNetworkGlobals.customization.equipped_head_user_item_id or
				user_item.id == ClientNetworkGlobals.customization.equipped_body_user_item_id
			)
			item_display.set_equipped(is_equipped)
			
			item_display.item_right_clicked.connect(_on_item_right_clicked.bind(user_item))
