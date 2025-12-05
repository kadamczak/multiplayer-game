extends CanvasLayer

signal user_details_clicked()
signal logout_clicked()

const USER_ITEM_DISPLAY = preload("res://scenes/ui/user_item_display.tscn")

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
@onready var items_container = $ItemsPanel/MarginContainer/VBoxContainer/ItemsScrollContainer/ItemsContainer
@onready var items_back_button = $ItemsPanel/MarginContainer/VBoxContainer/BackButton


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
	
	items_back_button.call_deferred("grab_focus")


func hide_items() -> void:
	items_panel.visible = false


func _on_items_pressed() -> void:
	show_items()


func _on_items_back_pressed() -> void:
	hide_items()
	show_menu()
