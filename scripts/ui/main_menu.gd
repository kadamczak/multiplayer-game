extends CanvasLayer

signal user_details_clicked()
signal logout_clicked()

@onready var menu_panel = $MenuPanel
@onready var user_details_button = $MenuPanel/MarginContainer/VBoxContainer/UserDetailsButton
@onready var logout_button = $MenuPanel/MarginContainer/VBoxContainer/LogoutButton
@onready var close_button = $MenuPanel/MarginContainer/VBoxContainer/CloseButton

@onready var user_details_panel = $UserDetailsPanel
@onready var username_label = $UserDetailsPanel/MarginContainer/VBoxContainer/UsernameLabel
@onready var balance_label = $UserDetailsPanel/MarginContainer/VBoxContainer/BalanceLabel
@onready var back_button = $UserDetailsPanel/MarginContainer/VBoxContainer/BackButton


func _ready() -> void:
	hide_menu()
	hide_user_details()
	
	user_details_button.pressed.connect(_on_user_details_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	close_button.pressed.connect(_on_close_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Set up focus
	user_details_button.focus_mode = Control.FOCUS_ALL
	logout_button.focus_mode = Control.FOCUS_ALL
	close_button.focus_mode = Control.FOCUS_ALL
	back_button.focus_mode = Control.FOCUS_ALL


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_main_menu"):
		if user_details_panel.visible:
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
	if not user_details_panel.visible:
		ClientNetworkGlobals.is_movement_blocking_ui_active = false


func show_user_details() -> void:
	menu_panel.visible = false
	user_details_panel.visible = true
	
	# Update labels with current data
	username_label.text = "Username: " + ClientNetworkGlobals.username
	balance_label.text = "Balance: " + str(ClientNetworkGlobals.balance) + " gold"
	
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
