extends Node2D

@onready var dialogue_ui = $UI/DialogueUI
@onready var merchant = $Merchant

func _ready() -> void:	
	merchant.player_interacted.connect(_on_merchant_interacted)
	dialogue_ui.dialogue_opened.connect(_on_dialogue_opened)
	dialogue_ui.dialogue_closed.connect(_on_dialogue_closed)


func _on_merchant_interacted() -> void:
	dialogue_ui.show_dialogue("Hello!")


func _on_dialogue_opened() -> void:
	ClientNetworkGlobals.is_dialogue_active = true


func _on_dialogue_closed() -> void:
	ClientNetworkGlobals.is_dialogue_active = false


func _input(event: InputEvent) -> void:
	if dialogue_ui and dialogue_ui.visible:
		if event.is_action_pressed("ui_cancel"):
			dialogue_ui.hide_dialogue()
			get_viewport().set_input_as_handled()
