extends Node2D

@onready var interaction_area = $InteractionArea
@onready var customization_ui = $CustomizationUI

var player_in_range: CharacterBody2D = null

# Define signal connections for real-time preview
const SIGNAL_MAPPINGS := {
	"color_applied": {"method": "set_body_color", "is_color": true},
	"eye_color_applied": {"method": "set_eye_color", "is_color": true},
	"wings_changed": {"method": "set_wing_type", "is_color": false},
	"wings_color_applied": {"method": "set_wing_color", "is_color": true},
	"horns_changed": {"method": "set_horn_type", "is_color": false},
	"horns_color_applied": {"method": "set_horn_color", "is_color": true},
	"markings_changed": {"method": "set_markings_type", "is_color": false},
	"markings_color_applied": {"method": "set_markings_color", "is_color": true}
}


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Connect all customization signals dynamically
	for signal_name in SIGNAL_MAPPINGS:
		customization_ui.get(signal_name).connect(_on_customization_changed.bind(SIGNAL_MAPPINGS[signal_name]))
	
	customization_ui.cancelled.connect(_on_ui_cancelled)
	customization_ui.closed.connect(_on_ui_closed)


func _on_body_entered(body: Node2D) -> void:
	if not _is_local_player(body):
		return
	
	player_in_range = body
	var customization = _get_customization(body)
	if not customization:
		return
	
	# Read and sync current customization to UI
	customization.read_from_player()
	_sync_ui_from_customization(customization)


func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		customization_ui.hide_ui()


func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_accept"):
		var customization = _get_customization(player_in_range)
		if customization:
			customization_ui.show_ui(
				customization.get_body_color(),
				customization.get_eye_color()
			)
			get_viewport().set_input_as_handled()


# Handle real-time customization changes
func _on_customization_changed(value, mapping: Dictionary) -> void:
	if not player_in_range:
		return
	
	var customization = _get_customization(player_in_range)
	if not customization:
		return
	
	# Call the appropriate setter method
	customization.call(mapping["method"], value)


func _on_ui_cancelled() -> void:
	if not player_in_range:
		return
	
	var customization = _get_customization(player_in_range)
	if not customization:
		return
	
	# Restore all original values
	var original_data := {
		"body_color": customization_ui.original_body_color,
		"eye_color": customization_ui.original_eye_color,
		"wing_type": customization_ui.original_wing_type,
		"wing_color": customization_ui.original_wing_color,
		"horn_type": customization_ui.original_horn_type,
		"horn_color": customization_ui.original_horn_color,
		"markings_type": customization_ui.original_markings_type,
		"markings_color": customization_ui.original_markings_color
	}
	
	customization.apply_from_dict(original_data)


func _on_ui_closed() -> void:
	pass


# Helper functions
func _is_local_player(body: Node2D) -> bool:
	return body is CharacterBody2D and body.has_method("get") and body.get("is_authority") and body.is_authority


func _get_customization(body: Node2D) -> PlayerCustomization:
	return body.get_node_or_null("PlayerCustomization") as PlayerCustomization


func _sync_ui_from_customization(customization: PlayerCustomization) -> void:
	# Update UI selections
	customization_ui.selected_wings = customization.get_wing_type()
	customization_ui.wings_color_picker.color = customization.get_wing_color()
	customization_ui._update_wings_buttons()
	
	customization_ui.selected_horns = customization.get_horn_type()
	customization_ui.horns_color_picker.color = customization.get_horn_color()
	customization_ui._update_horns_buttons()
	
	customization_ui.selected_markings = customization.get_markings_type()
	customization_ui.markings_color_picker.color = customization.get_markings_color()
	customization_ui._update_markings_buttons()
