extends Node2D

@onready var merchant_ui = $UI/MerchantUI
@onready var merchant = $Merchant

func _ready() -> void:	
	merchant.player_interacted.connect(_on_merchant_interacted)
	merchant_ui.dialogue_opened.connect(_on_dialogue_opened)
	merchant_ui.dialogue_closed.connect(_on_dialogue_closed)


func _on_merchant_interacted() -> void:
	merchant_ui.show_dialogue("Hello!")


func _on_dialogue_opened() -> void:
	ClientNetworkGlobals.is_dialogue_active = true


func _on_dialogue_closed() -> void:
	ClientNetworkGlobals.is_dialogue_active = false


func _input(event: InputEvent) -> void:
	if merchant_ui and merchant_ui.visible:
		if event.is_action_pressed("ui_cancel"):
			merchant_ui.hide_dialogue()
			get_viewport().set_input_as_handled()
