extends CanvasLayer

signal part_type_changed(part_name: String, type: int)
signal part_color_changed(part_name: String, color: Color)
signal cancelled()
signal closed()

@onready var panel = $Panel
@onready var apply_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/ApplyButton
@onready var close_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton
@onready var lock_colors_checkbox = $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/LockColorsCheckbox

# Color pickers for each body part
@onready var color_pickers := {
	"Head": $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/HeadColorSection/HeadColorPicker,
	"Body": $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/BodyColorSection/BodyColorPicker,
	"Eyes": $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/EyesColorSection/EyesColorPicker,
	"Tail": $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/TailColorSection/TailColorPicker,
	"Wings": $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsColorPicker,
	"Horns": $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsColorPicker
}

# Feature type buttons (only for parts with multiple types)
@onready var wings_buttons := {
	CustomizationConstants.Wings_Type.NO_WINGS: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/NoWingsButton,
	CustomizationConstants.Wings_Type.CLASSIC: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/Wings1Button,
	CustomizationConstants.Wings_Type.FEATHERED: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/Wings2Button
}

@onready var horns_buttons := {
	CustomizationConstants.Horns_Type.NO_HORNS: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsContainer/NoHornsButton,
	CustomizationConstants.Horns_Type.CLASSIC: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsContainer/Horns1Button
}

# Current selections
var current_parts := {}

# Store original state for cancel functionality
var original_state := {}

func _ready() -> void:
	hide_ui()
	
	# Connect buttons
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect wings type buttons
	for type in wings_buttons:
		wings_buttons[type].pressed.connect(_on_wings_type_selected.bind(type))
	
	# Connect horns type buttons
	for type in horns_buttons:
		horns_buttons[type].pressed.connect(_on_horns_type_selected.bind(type))
	
	# Connect color pickers
	for part_name in color_pickers:
		if color_pickers[part_name]:
			color_pickers[part_name].color_changed.connect(_on_color_changed.bind(part_name))
	
	# Connect lock colors checkbox
	lock_colors_checkbox.toggled.connect(_on_lock_colors_toggled)
	
	# Set up focus navigation
	apply_button.focus_neighbor_right = close_button.get_path()
	close_button.focus_neighbor_left = apply_button.get_path()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel.visible:
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func show_ui(customization_parts: Dictionary) -> void:
	panel.visible = true
	
	# Store current state
	current_parts = {}
	original_state = {}
	
	for part_name in customization_parts:
		var part = customization_parts[part_name]
		current_parts[part_name] = {
			"type": part.line_type,
			"color": part.color
		}
		original_state[part_name] = {
			"type": part.line_type,
			"color": part.color
		}
		
		# Update color pickers
		if part_name in color_pickers and color_pickers[part_name]:
			color_pickers[part_name].color = part.color
	
	# Update Wings buttons
	if "Wings" in current_parts:
		_update_type_buttons(wings_buttons, current_parts["Wings"]["type"])
		_update_wings_color_visibility()
	
	# Update Horns buttons
	if "Horns" in current_parts:
		_update_type_buttons(horns_buttons, current_parts["Horns"]["type"])
		_update_horns_color_visibility()
	
	ClientNetworkGlobals.is_movement_blocking_ui_active = true
	apply_button.grab_focus()


func hide_ui() -> void:
	panel.visible = false
	if not ClientNetworkGlobals.is_movement_blocking_ui_active:
		return
	ClientNetworkGlobals.is_movement_blocking_ui_active = false


func _on_wings_type_selected(type: int) -> void:
	current_parts["Wings"]["type"] = type
	_update_type_buttons(wings_buttons, type)
	_update_wings_color_visibility()
	part_type_changed.emit("Wings", type)


func _on_horns_type_selected(type: int) -> void:
	current_parts["Horns"]["type"] = type
	_update_type_buttons(horns_buttons, type)
	_update_horns_color_visibility()
	part_type_changed.emit("Horns", type)


func _on_color_changed(color: Color, part_name: String) -> void:
	if part_name in current_parts:
		current_parts[part_name]["color"] = color
	
	# If colors are locked and this is one of the body parts, sync them
	if lock_colors_checkbox.button_pressed and part_name in ["Head", "Body", "Tail"]:
		_sync_locked_colors(color, part_name)
	
	part_color_changed.emit(part_name, color)


func _on_lock_colors_toggled(is_pressed: bool) -> void:
	# When toggled on, sync all body colors to Head color
	if is_pressed and "Head" in current_parts:
		var head_color = current_parts["Head"]["color"]
		_sync_locked_colors(head_color, "Head")


func _sync_locked_colors(color: Color, source_part: String) -> void:
	# Sync Head, Body, and Tail to the same color
	var locked_parts = ["Head", "Body", "Tail"]
	
	for part_name in locked_parts:
		if part_name == source_part:
			continue
		
		if part_name in current_parts:
			current_parts[part_name]["color"] = color
			
			# Update the color picker UI
			if part_name in color_pickers and color_pickers[part_name]:
				color_pickers[part_name].color = color
			
			# Emit signal for visual update
			part_color_changed.emit(part_name, color)


func _update_type_buttons(buttons: Dictionary, selected_type: int) -> void:
	for type in buttons:
		if buttons[type]:
			buttons[type].disabled = (type == selected_type)


func _update_wings_color_visibility() -> void:
	if "Wings" in color_pickers and color_pickers["Wings"]:
		color_pickers["Wings"].visible = (current_parts["Wings"]["type"] != CustomizationConstants.Wings_Type.NO_WINGS)


func _update_horns_color_visibility() -> void:
	if "Horns" in color_pickers and color_pickers["Horns"]:
		color_pickers["Horns"].visible = (current_parts["Horns"]["type"] != CustomizationConstants.Horns_Type.NO_HORNS)


func _on_apply_pressed() -> void:
	# Emit all part changes
	for part_name in current_parts:
		part_type_changed.emit(part_name, current_parts[part_name]["type"])
		part_color_changed.emit(part_name, current_parts[part_name]["color"])
	
	# TODO: Send customization update to API
	# var result = await UserAPI.update_user_customization(...)
	
	DebugLogger.log("Customization updated successfully")
	hide_ui()


func _on_close_pressed() -> void:
	# Revert all parts to original state
	for part_name in original_state:
		current_parts[part_name]["type"] = original_state[part_name]["type"]
		current_parts[part_name]["color"] = original_state[part_name]["color"]
		
		# Update UI elements
		if part_name in color_pickers and color_pickers[part_name]:
			color_pickers[part_name].color = original_state[part_name]["color"]
	
	# Update button states
	if "Wings" in original_state:
		_update_type_buttons(wings_buttons, original_state["Wings"]["type"])
		_update_wings_color_visibility()
	
	if "Horns" in original_state:
		_update_type_buttons(horns_buttons, original_state["Horns"]["type"])
		_update_horns_color_visibility()
	
	# Emit cancelled signal to restore original state in player
	cancelled.emit()
	closed.emit()
	hide_ui()


