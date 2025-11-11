extends Node2D

@onready var interaction_area = $InteractionArea
@onready var customization_ui = $CustomizationUI

var player_in_range: CharacterBody2D = null
var current_color: Color = Color.WHITE

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	customization_ui.color_applied.connect(_on_color_applied)
	customization_ui.closed.connect(_on_ui_closed)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			player_in_range = body
			# Get current color from player if available
			if body.has_node("Sprite/Tail_Color"):
				current_color = body.get_node("Sprite/Tail_Color").self_modulate

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		customization_ui.hide_ui()

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_interact"):
		customization_ui.show_ui(current_color)
		get_viewport().set_input_as_handled()

func _on_color_applied(color: Color) -> void:
	current_color = color
	apply_color_to_player(player_in_range, color)

func _on_ui_closed() -> void:
	pass

func apply_color_to_player(player: CharacterBody2D, color: Color) -> void:
	if not player:
		return
	
	# Apply color to Tail_Color sprite
	if player.has_node("Sprite/Tail_Color"):
		player.get_node("Sprite/Tail_Color").self_modulate = color
	
	# Apply color to Body_Color sprite
	if player.has_node("Sprite/Body_Color"):
		player.get_node("Sprite/Body_Color").self_modulate = color



	# # Apply color to Wings_Color sprite if it exists
	# if player.has_node("Sprite/Wings_Color"):
	# 	player.get_node("Sprite/Wings_Color").self_modulate = color

