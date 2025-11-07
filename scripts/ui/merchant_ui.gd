extends CanvasLayer

signal dialogue_opened()
signal dialogue_closed()

@onready var panel = $Panel
@onready var dialogue_label = $Panel/HBoxContainer/DialogueLabel


func _ready() -> void:
	hide_dialogue()


func show_dialogue(text: String) -> void:
	dialogue_label.text = text
	panel.visible = true
	dialogue_opened.emit()


func hide_dialogue() -> void:
	panel.visible = false
	dialogue_closed.emit()
