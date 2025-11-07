extends CanvasLayer

@onready var panel = $Panel
@onready var dialogue_label = $Panel/HBoxContainer/DialogueLabel


func _ready() -> void:
	hide_dialogue()


func show_dialogue(text: String) -> void:
	dialogue_label.text = text
	panel.visible = true


func hide_dialogue() -> void:
	panel.visible = false
