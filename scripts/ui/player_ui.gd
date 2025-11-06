extends Control

@onready var balance_label = $BalanceContainer/BalanceLabel

func _ready():
	ClientNetworkGlobals.balance_changed.connect(update_balance_display)
	update_balance_display(ClientNetworkGlobals.balance)
	
	# Listen for token refresh failure to handle forced logout
	AuthManager.token_refresh_failed.connect(_on_token_expired)

func update_balance_display(amount: int) -> void:
	balance_label.text = str(amount)

func _on_token_expired() -> void:
	DebugLogger.log("Session expired - redirecting to login")
	get_tree().change_scene_to_file("res://scenes/ui/login_scene.tscn")
