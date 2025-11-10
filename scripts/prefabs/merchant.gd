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
	merchant_ui.talk_clicked.connect(_on_talk_clicked)
	merchant_ui.trade_clicked.connect(_on_trade_clicked)
	merchant_ui.back_from_trade_clicked.connect(_on_back_from_trade_clicked)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			local_player_in_area = true


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			local_player_in_area = false

func _input(event: InputEvent) -> void:
	if merchant_ui.panel.visible or merchant_ui.trade_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			if merchant_ui.trade_panel.visible:
				_on_back_from_trade_clicked()
			else:
				merchant_ui.hide_dialogue()
			get_viewport().set_input_as_handled()
	elif local_player_in_area and event.is_action_pressed("ui_accept"):
		merchant_ui.show_dialogue(greeting_text, "Talk")
		get_viewport().set_input_as_handled()


func _on_talk_clicked() -> void:
	merchant_ui.show_dialogue(talk_text, "Talk")


func _on_trade_clicked() -> void:
	merchant_ui.show_trading_view()
	
	var response = await MerchantAPI.get_merchant_offers(merchant_id)
	
	if response.success:
		merchant_ui.display_offers(response.data)
	else:
		var problem: ApiResponse.ProblemDetails = response.problem
		merchant_ui.show_error("Failed to load offers: " + problem.title)


func _on_back_from_trade_clicked() -> void:
	merchant_ui.show_dialogue(greeting_text, "Trade")
