extends CanvasLayer

signal talk_clicked()
signal trade_clicked()

@onready var panel = $Panel
@onready var dialogue_label = $Panel/HBoxContainer/RightSide/DialogueLabel
@onready var talk_button = $Panel/HBoxContainer/RightSide/ButtonContainer/TalkButton
@onready var trade_button = $Panel/HBoxContainer/RightSide/ButtonContainer/TradeButton


func _ready() -> void:
	hide_dialogue()
	talk_button.pressed.connect(_on_talk_pressed)
	trade_button.pressed.connect(_on_trade_pressed)
	talk_button.focus_mode = Control.FOCUS_ALL


func show_dialogue(text: String, button_selected: String) -> void:
	ClientNetworkGlobals.is_movement_blocking_ui_active = true
	dialogue_label.text = text
	panel.visible = true

	if button_selected == "Talk":
		talk_button.call_deferred("grab_focus")
	elif button_selected == "Trade":
		trade_button.call_deferred("grab_focus")


func hide_dialogue() -> void:
	panel.visible = false
	ClientNetworkGlobals.is_movement_blocking_ui_active = false


func _on_talk_pressed() -> void:
	talk_clicked.emit()


func _on_trade_pressed() -> void:
	trade_clicked.emit()
