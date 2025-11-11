extends Node2D

@onready var main_menu = $UI/MainMenu

func _ready() -> void:
	if main_menu:
		main_menu.logout_clicked.connect(_on_logout_clicked)

func _on_logout_clicked() -> void:
	# Clear authentication tokens
	AuthManager.clear_tokens()
	
	# Reset client globals
	ClientNetworkGlobals.username = ""
	ClientNetworkGlobals.balance = 0
	ClientNetworkGlobals.is_movement_blocking_ui_active = false
	
	# Return to login scene
	get_tree().change_scene_to_file("res://scenes/ui/login_scene.tscn")
