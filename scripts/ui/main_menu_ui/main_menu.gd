extends CanvasLayer

signal logout_clicked()

@onready var menu_panel = $MenuPanel
@onready var user_details_button = $MenuPanel/MarginContainer/VBoxContainer/UserDetailsButton
@onready var items_button = $MenuPanel/MarginContainer/VBoxContainer/ItemsButton
@onready var logout_button = $MenuPanel/MarginContainer/VBoxContainer/LogoutButton
@onready var close_button = $MenuPanel/MarginContainer/VBoxContainer/CloseButton

@onready var user_details_panel = $UserDetailsPanel
@onready var items_panel = $ItemsPanel

enum MenuState { CLOSED, MAIN_MENU, ITEMS_PANEL, USER_DETAILS }
var current_menu_state := MenuState.CLOSED


func _ready() -> void:
	hide_all()
	connect_signals()
	set_focus_modes()


func hide_all() -> void:
	menu_panel.visible = false
	user_details_panel.hide()
	items_panel.hide()


func connect_signals() -> void:
	user_details_button.pressed.connect(_on_user_details_pressed)
	items_button.pressed.connect(_on_items_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	user_details_panel.back_pressed.connect(_on_user_details_back_pressed)
	items_panel.back_pressed.connect(_on_items_back_pressed)


func set_focus_modes() -> void:
	user_details_button.focus_mode = Control.FOCUS_ALL
	items_button.focus_mode = Control.FOCUS_ALL
	logout_button.focus_mode = Control.FOCUS_ALL
	close_button.focus_mode = Control.FOCUS_ALL


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_main_menu"):
		if current_menu_state == MenuState.CLOSED:
			ClientNetworkGlobals.is_movement_blocking_ui_active = true
			show_main_menu()
		elif current_menu_state == MenuState.USER_DETAILS:
			_on_user_details_back_pressed()
		elif current_menu_state == MenuState.ITEMS_PANEL:
			_on_items_back_pressed()
		elif current_menu_state == MenuState.MAIN_MENU:
			_on_close_pressed()
		
		get_viewport().set_input_as_handled()


func show_main_menu() -> void:
	menu_panel.visible = true
	current_menu_state = MenuState.MAIN_MENU
	user_details_button.call_deferred("grab_focus")


func hide_main_menu() -> void:
	menu_panel.visible = false


func _on_user_details_pressed() -> void:
	menu_panel.visible = false
	user_details_panel.show_panel()
	current_menu_state = MenuState.USER_DETAILS


func _on_items_pressed() -> void:
	menu_panel.visible = false
	items_panel.show_panel()
	current_menu_state = MenuState.ITEMS_PANEL


func _on_user_details_back_pressed() -> void:
	user_details_panel.hide()
	show_main_menu()


func _on_items_back_pressed() -> void:
	items_panel.hide()
	show_main_menu()


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
	hide_main_menu()
	ClientNetworkGlobals.is_movement_blocking_ui_active = false
	current_menu_state = MenuState.CLOSED
