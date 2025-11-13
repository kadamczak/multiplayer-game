extends Node2D

@onready var interaction_area = $InteractionArea
@onready var customization_ui = $CustomizationUI

var player_in_range: CharacterBody2D = null

# Map UI signals to customization data keys
const SIGNAL_TO_KEY := {
	"color_applied": "body_color",
	"eye_color_applied": "eye_color",
	"wings_changed": "wing_type",
	"wings_color_applied": "wing_color",
	"horns_changed": "horn_type",
	"horns_color_applied": "horn_color",
	"markings_changed": "markings_type",
	"markings_color_applied": "markings_color"
}


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Connect all customization signals dynamically
	for signal_name in SIGNAL_TO_KEY:
		customization_ui.get(signal_name).connect(_apply_customization.bind(SIGNAL_TO_KEY[signal_name]))
	
	customization_ui.cancelled.connect(_on_ui_cancelled)


func _on_body_entered(body: Node2D) -> void:
	if not _is_local_player(body):
		return
	
	player_in_range = body
	var customization = _get_customization()
	if not customization:
		return
	
	customization.read_from_player()
	_sync_ui_with_customization(customization)


func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		customization_ui.hide_ui()


func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_accept"):
		var customization = _get_customization()
		if customization:
			customization_ui.show_ui(customization.get_color("body_color"), customization.get_color("eye_color"))
			get_viewport().set_input_as_handled()


func _apply_customization(value, key: String) -> void:
	var customization = _get_customization()
	if customization:
		customization.set_customization(key, value)


func _on_ui_cancelled() -> void:
	var customization = _get_customization()
	if customization:
		customization.apply_from_dict(customization_ui.original_state)


func _is_local_player(body: Node2D) -> bool:
	return (body is CharacterBody2D 
		and body.has_method("get") 
		and body.get("is_authority") 
		and body.is_authority)


func _get_customization() -> PlayerCustomization:
	if not player_in_range:
		return null
	return player_in_range.get_node_or_null("PlayerCustomization") as PlayerCustomization


func _sync_ui_with_customization(customization: PlayerCustomization) -> void:
	customization_ui.selected_wings = customization.get_feature_type("wing_type")
	customization_ui.selected_horns = customization.get_feature_type("horn_type")
	customization_ui.selected_markings = customization.get_feature_type("markings_type")
	
	customization_ui.wings_color_picker.color = customization.get_color("wing_color")
	customization_ui.horns_color_picker.color = customization.get_color("horn_color")
	customization_ui.markings_color_picker.color = customization.get_color("markings_color")
	
	customization_ui._update_all_buttons()
