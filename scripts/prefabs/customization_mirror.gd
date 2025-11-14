extends Node2D

@onready var interaction_area = $InteractionArea
@onready var customization_ui = $CustomizationUI

var player_in_range: CharacterBody2D = null


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Connect UI signals
	customization_ui.part_type_changed.connect(_on_part_type_changed)
	customization_ui.part_color_changed.connect(_on_part_color_changed)
	customization_ui.cancelled.connect(_on_ui_cancelled)


func _on_body_entered(body: Node2D) -> void:
	if not _is_local_player(body):
		return
	
	player_in_range = body


func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		customization_ui.hide_ui()


func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("ui_accept"):
		var customization = _get_customization()
		if customization and customization.active_player_customization:
			customization_ui.show_ui(customization.active_player_customization)
			get_viewport().set_input_as_handled()


func _on_part_type_changed(part_name: String, type: int) -> void:
	var customization = _get_customization()
	if customization and part_name in customization.active_player_customization:
		var part = customization.active_player_customization[part_name]
		part.line_type = type
		customization.apply_customization(part_name, part)


func _on_part_color_changed(part_name: String, color: Color) -> void:
	var customization = _get_customization()
	if customization and part_name in customization.active_player_customization:
		var part = customization.active_player_customization[part_name]
		part.color = color
		customization.apply_customization(part_name, part)


func _on_ui_cancelled() -> void:
	var customization = _get_customization()
	if customization:
		# Restore from original state stored in UI
		for part_name in customization_ui.original_state:
			if part_name in customization.active_player_customization:
				var part = customization.active_player_customization[part_name]
				part.line_type = customization_ui.original_state[part_name]["type"]
				part.color = customization_ui.original_state[part_name]["color"]
				customization.apply_customization(part_name, part)


func _is_local_player(body: Node2D) -> bool:
	return (body is CharacterBody2D 
		and body.has_method("get") 
		and body.get("is_authority") 
		and body.is_authority)


func _get_customization() -> PlayerCustomization:
	if not player_in_range:
		return null
	return player_in_range.get_node_or_null("PlayerCustomization") as PlayerCustomization
