extends Node2D

@onready var interaction_area = $InteractionArea
@onready var customization_ui = $CustomizationUI

var player_in_range: CharacterBody2D = null

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	customization_ui.color_applied.connect(_on_color_applied)
	customization_ui.eye_color_applied.connect(_on_eye_color_applied)
	customization_ui.wings_changed.connect(_on_wings_changed)
	customization_ui.wings_color_applied.connect(_on_wings_color_applied)
	customization_ui.horns_changed.connect(_on_horns_changed)
	customization_ui.horns_color_applied.connect(_on_horns_color_applied)
	customization_ui.markings_changed.connect(_on_markings_changed)
	customization_ui.markings_color_applied.connect(_on_markings_color_applied)
	customization_ui.cancelled.connect(_on_ui_cancelled)
	customization_ui.closed.connect(_on_ui_closed)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("get") and body.get("is_authority"):
		if body.is_authority:
			player_in_range = body
			
			# Get the customization component
			var customization = body.get_node_or_null("PlayerCustomization")
			if not customization:
				return
			
			# Read current customization from the player
			customization.read_from_player()
			
			# Update UI with current selections
			customization_ui.selected_wings = customization.wing_type
			customization_ui.wings_color_picker.color = customization.wing_color
			customization_ui._update_wings_buttons()
			customization_ui.selected_horns = customization.horn_type
			customization_ui.horns_color_picker.color = customization.horn_color
			customization_ui._update_horns_buttons()
			customization_ui.selected_markings = customization.markings_type
			customization_ui.markings_color_picker.color = customization.markings_color
			customization_ui._update_markings_buttons()

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		customization_ui.hide_ui()

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_accept"):
		var customization = player_in_range.get_node_or_null("PlayerCustomization")
		if customization:
			customization_ui.show_ui(customization.body_color, customization.eye_color)
			get_viewport().set_input_as_handled()

func _on_color_applied(color: Color) -> void:
	if not player_in_range:
		return
	var customization = player_in_range.get_node_or_null("PlayerCustomization")
	if customization:
		customization.apply_body_color(color)

func _on_eye_color_applied(eye_color: Color) -> void:
	if not player_in_range:
		return
	var customization = player_in_range.get_node_or_null("PlayerCustomization")
	if customization:
		customization.apply_eye_color(eye_color)

func _on_wings_changed(wing_type: int) -> void:
	if not player_in_range:
		return
	var customization = player_in_range.get_node_or_null("PlayerCustomization")
	if customization:
		customization.apply_wings(wing_type)

func _on_wings_color_applied(color: Color) -> void:
	if not player_in_range:
		return
	var customization = player_in_range.get_node_or_null("PlayerCustomization")
	if customization:
		customization.apply_wings_color(color)

func _on_horns_changed(horn_type: int) -> void:
	if not player_in_range:
		return
	var customization = player_in_range.get_node_or_null("PlayerCustomization")
	if customization:
		customization.apply_horns(horn_type)

func _on_horns_color_applied(color: Color) -> void:
	if not player_in_range:
		return
	var customization = player_in_range.get_node_or_null("PlayerCustomization")
	if customization:
		customization.apply_horns_color(color)

func _on_markings_changed(markings_type: int) -> void:
	if not player_in_range:
		return
	var customization = player_in_range.get_node_or_null("PlayerCustomization")
	if customization:
		customization.apply_markings(markings_type)

func _on_markings_color_applied(color: Color) -> void:
	if not player_in_range:
		return
	var customization = player_in_range.get_node_or_null("PlayerCustomization")
	if customization:
		customization.apply_markings_color(color)

func _on_ui_cancelled() -> void:
	if not player_in_range:
		return
	var customization = player_in_range.get_node_or_null("PlayerCustomization")
	if not customization:
		return
	
	# Restore original state from the UI
	customization.apply_body_color(customization_ui.original_body_color)
	customization.apply_eye_color(customization_ui.original_eye_color)
	customization.apply_wings(customization_ui.original_wings_type)
	customization.apply_wings_color(customization_ui.original_wings_color)
	customization.apply_horns(customization_ui.original_horns_type)
	customization.apply_horns_color(customization_ui.original_horns_color)
	customization.apply_markings(customization_ui.original_markings_type)
	customization.apply_markings_color(customization_ui.original_markings_color)

func _on_ui_closed() -> void:
	pass
