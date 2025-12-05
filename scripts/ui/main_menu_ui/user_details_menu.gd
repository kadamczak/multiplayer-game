extends Panel

signal back_pressed()

@onready var username_label = $MarginContainer/VBoxContainer/UsernameLabel
@onready var balance_label = $MarginContainer/VBoxContainer/BalanceLabel
@onready var back_button = $MarginContainer/VBoxContainer/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.focus_mode = Control.FOCUS_ALL
	hide()


func show_panel() -> void:
	username_label.text = "Username: " + ClientNetworkGlobals.username
	balance_label.text = "Balance: " + str(ClientNetworkGlobals.balance) + " Gems"
	show()
	back_button.call_deferred("grab_focus")


func hide_panel() -> void:
	hide()


func _on_back_pressed() -> void:
	back_pressed.emit()
