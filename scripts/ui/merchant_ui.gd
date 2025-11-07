extends CanvasLayer

@onready var panel = $Panel
@onready var dialogue_label = $Panel/HBoxContainer/DialogueLabel


func _ready() -> void:
	hide_dialogue()


func show_dialogue(text: String) -> void:
	ClientNetworkGlobals.is_movement_blocking_ui_active = true
	dialogue_label.text = text
	panel.visible = true


func hide_dialogue() -> void:
	panel.visible = false
	ClientNetworkGlobals.is_movement_blocking_ui_active = false
