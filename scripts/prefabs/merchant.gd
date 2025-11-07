extends Node2D

@export var merchant_id: int = -1
@export var greeting_text: String = "Greeting text!"
@export var talk_text: String = "Talk text!"
@export var trade_text: String = "Trade text!"

var local_player_in_area: bool = false

@onready var merchant_ui: CanvasLayer = $MerchantUI
@onready var area_2d = $Area2D


func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			local_player_in_area = true


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			local_player_in_area = false

func _input(event: InputEvent) -> void:
	if merchant_ui.panel.visible:
		if event.is_action_pressed("ui_cancel"):
			merchant_ui.hide_dialogue()
			get_viewport().set_input_as_handled()
	elif local_player_in_area and event.is_action_pressed("ui_action"):
		merchant_ui.show_dialogue(greeting_text)
		get_viewport().set_input_as_handled()