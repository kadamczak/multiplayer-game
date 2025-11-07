extends Node2D

@onready var dialogue_ui = $UI/DialogueUI
@onready var merchant = $Merchant

func _ready() -> void:	
	merchant.player_interacted.connect(_on_merchant_interacted)


func _on_merchant_interacted() -> void:
	dialogue_ui.show_dialogue("Hello!")


func _input(event: InputEvent) -> void:
	if dialogue_ui and dialogue_ui.visible:
		if event.is_action_pressed("ui_cancel"):
			dialogue_ui.hide_dialogue()
			get_viewport().set_input_as_handled()
