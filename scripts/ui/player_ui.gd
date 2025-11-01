extends Control

@onready var balance_label = $BalanceContainer/BalanceLabel

func _ready():
	ClientNetworkGlobals.balance_changed.connect(update_balance_display)
	update_balance_display(ClientNetworkGlobals.balance)

func update_balance_display(amount: int) -> void:
	balance_label.text = str(amount)
