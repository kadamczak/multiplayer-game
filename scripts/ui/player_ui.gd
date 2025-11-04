extends Control

@onready var balance_label = $BalanceContainer/BalanceLabel

func _ready():
	ClientNetworkGlobals.balance_changed.connect(update_balance_display)
	update_balance_display(ClientNetworkGlobals.balance)
	
	# Listen for token expiry to handle forced logout
	#AuthManager.token_expired.connect(_on_token_expired)

func update_balance_display(amount: int) -> void:
	balance_label.text = str(amount)

func _on_token_expired() -> void:
	# Token expired and couldn't be refreshed - need to re-login
	DebugLogger.log("Session expired - redirecting to login")
	get_tree().change_scene_to_file("res://scenes/ui/login_scene.tscn")
