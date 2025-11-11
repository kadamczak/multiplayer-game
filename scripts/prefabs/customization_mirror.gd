extends Node2D

@onready var interaction_area = $InteractionArea
@onready var customization_ui = $CustomizationUI

var player_in_range: CharacterBody2D = null
var current_color: Color = Color.WHITE
var current_eye_color: Color = Color.WHITE
var current_wings: int = 1  # Default to Wings 1

# Preload wing textures
var wings_textures = {
	1: {
		"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1.png"),
		"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1_Color.png")
	},
	2: {
		"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2.png"),
		"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2_Color.png")
	}
}

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	customization_ui.color_applied.connect(_on_color_applied)
	customization_ui.eye_color_applied.connect(_on_eye_color_applied)
	customization_ui.wings_changed.connect(_on_wings_changed)
	customization_ui.closed.connect(_on_ui_closed)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			player_in_range = body
			# Get current color from player if available
			if body.has_node("Sprite/Tail_Color"):
				current_color = body.get_node("Sprite/Tail_Color").self_modulate
			
			# Get current eye color
			if body.has_node("Sprite/Eyes_Color"):
				current_eye_color = body.get_node("Sprite/Eyes_Color").self_modulate
			
			# Get current wing state
			if body.has_node("Sprite/Wings"):
				var wings_visible = body.get_node("Sprite/Wings").visible
				if not wings_visible:
					current_wings = 0
				else:
					# Check which texture is loaded to determine wings type
					var wings_texture = body.get_node("Sprite/Wings").texture
					if wings_texture == wings_textures[1]["base"]:
						current_wings = 1
					elif wings_texture == wings_textures[2]["base"]:
						current_wings = 2
			
			# Update UI with current wing selection
			customization_ui.selected_wings = current_wings
			customization_ui._update_wings_buttons()

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		customization_ui.hide_ui()

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_interact"):
		customization_ui.show_ui(current_color, current_eye_color)
		get_viewport().set_input_as_handled()

func _on_color_applied(color: Color) -> void:
	current_color = color
	apply_color_to_player(player_in_range, color)

func _on_eye_color_applied(eye_color: Color) -> void:
	current_eye_color = eye_color
	apply_eye_color_to_player(player_in_range, eye_color)

func _on_wings_changed(wings_type: int) -> void:
	current_wings = wings_type
	apply_wings_to_player(player_in_range, wings_type)

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
		
	if player.has_node("Sprite/Head_Color"):
		player.get_node("Sprite/Head_Color").self_modulate = color

	# Apply color to Wings_Color sprite if it exists
	if player.has_node("Sprite/Wings_Color"):
		player.get_node("Sprite/Wings_Color").self_modulate = color

func apply_eye_color_to_player(player: CharacterBody2D, eye_color: Color) -> void:
	if not player:
		return
	
	# Apply color to Eyes_Color sprite
	if player.has_node("Sprite/Eyes_Color"):
		player.get_node("Sprite/Eyes_Color").self_modulate = eye_color

func apply_wings_to_player(player: CharacterBody2D, wings_type: int) -> void:
	if not player:
		return
	
	var wings_node = player.get_node_or_null("Sprite/Wings")
	var wings_color_node = player.get_node_or_null("Sprite/Wings_Color")
	
	if not wings_node or not wings_color_node:
		return
	
	if wings_type == 0:
		# No wings - hide both nodes
		wings_node.visible = false
		wings_color_node.visible = false
	else:
		# Wings 1 or 2 - show nodes and set textures
		wings_node.visible = true
		wings_color_node.visible = true
		
		if wings_type in wings_textures:
			wings_node.texture = wings_textures[wings_type]["base"]
			wings_color_node.texture = wings_textures[wings_type]["color"]

