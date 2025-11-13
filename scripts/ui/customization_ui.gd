extends CanvasLayer

signal color_applied(color: Color)
signal eye_color_applied(eye_color: Color)
signal wings_changed(wing_type: int)
signal wings_color_applied(color: Color)
signal horns_changed(horn_type: int)
signal horns_color_applied(color: Color)
signal markings_changed(markings_type: int)
signal markings_color_applied(color: Color)
signal cancelled()
signal closed()

@onready var panel = $Panel
@onready var color_picker_button = $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/BodyColorSection/ColorPickerButton
@onready var eye_color_picker_button = $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/EyeColorSection/EyeColorPickerButton
@onready var wings_color_picker = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsColorPicker
@onready var horns_color_picker = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsColorPicker
@onready var markings_color_picker = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/MarkingsRow/MarkingsColorPicker
@onready var apply_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/ApplyButton
@onready var close_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton

# Feature button groups
@onready var wings_buttons = {
	0: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/NoWingsButton,
	1: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/Wings1Button,
	2: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/Wings2Button
}

@onready var horns_buttons = {
	0: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsContainer/NoHornsButton,
	1: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsContainer/Horns1Button
}

@onready var markings_buttons = {
	0: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/MarkingsRow/MarkingsContainer/NoMarkingsButton,
	1: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/MarkingsRow/MarkingsContainer/Markings1Button,
	2: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/MarkingsRow/MarkingsContainer/Markings2Button
}

var selected_wings: int = 1
var selected_horns: int = 1
var selected_markings: int = 0

# Store original state for cancel functionality
var original_state := {}


func _ready() -> void:
	hide_ui()
	
	# Connect buttons
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect feature buttons dynamically
	for type in wings_buttons:
		wings_buttons[type].pressed.connect(_on_feature_selected.bind("wings", type, wings_changed))
	for type in horns_buttons:
		horns_buttons[type].pressed.connect(_on_feature_selected.bind("horns", type, horns_changed))
	for type in markings_buttons:
		markings_buttons[type].pressed.connect(_on_feature_selected.bind("markings", type, markings_changed))
	
	# Connect color picker changes
	color_picker_button.color_changed.connect(color_applied.emit)
	eye_color_picker_button.color_changed.connect(eye_color_applied.emit)
	wings_color_picker.color_changed.connect(wings_color_applied.emit)
	horns_color_picker.color_changed.connect(horns_color_applied.emit)
	markings_color_picker.color_changed.connect(markings_color_applied.emit)
	
	# Set up focus navigation
	apply_button.focus_neighbor_right = close_button.get_path()
	close_button.focus_neighbor_left = apply_button.get_path()
	
	_update_all_buttons()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel.visible:
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func show_ui(current_color: Color = Color.WHITE, current_eye_color: Color = Color.WHITE) -> void:
	panel.visible = true
	color_picker_button.color = current_color
	eye_color_picker_button.color = current_eye_color
	
	# Store original state
	original_state = {
		"body_color": current_color,
		"eye_color": current_eye_color,
		"wing_type": selected_wings,
		"wing_color": wings_color_picker.color,
		"horn_type": selected_horns,
		"horn_color": horns_color_picker.color,
		"markings_type": selected_markings,
		"markings_color": markings_color_picker.color
	}
	
	ClientNetworkGlobals.is_movement_blocking_ui_active = true
	apply_button.grab_focus()


func hide_ui() -> void:
	panel.visible = false
	if not ClientNetworkGlobals.is_movement_blocking_ui_active:
		return
	ClientNetworkGlobals.is_movement_blocking_ui_active = false


func _on_feature_selected(feature_name: String, type: int, change_signal: Signal) -> void:
	match feature_name:
		"wings":
			selected_wings = type
			_update_feature_buttons(wings_buttons, type)
		"horns":
			selected_horns = type
			_update_feature_buttons(horns_buttons, type)
		"markings":
			selected_markings = type
			_update_feature_buttons(markings_buttons, type)
	
	_update_color_pickers_visibility()
	change_signal.emit(type)


func _update_feature_buttons(buttons: Dictionary, selected_type: int) -> void:
	for type in buttons:
		buttons[type].disabled = (type == selected_type)


func _update_all_buttons() -> void:
	_update_feature_buttons(wings_buttons, selected_wings)
	_update_feature_buttons(horns_buttons, selected_horns)
	_update_feature_buttons(markings_buttons, selected_markings)
	_update_color_pickers_visibility()


func _update_color_pickers_visibility() -> void:
	wings_color_picker.visible = (selected_wings > 0)
	horns_color_picker.visible = (selected_horns > 0)
	markings_color_picker.visible = (selected_markings > 0)


func _on_apply_pressed() -> void:
	# Emit all color signals
	color_applied.emit(color_picker_button.color)
	eye_color_applied.emit(eye_color_picker_button.color)
	wings_color_applied.emit(wings_color_picker.color)
	horns_color_applied.emit(horns_color_picker.color)
	markings_color_applied.emit(markings_color_picker.color)
	
	# Send customization update to API
	var result = await UserAPI.update_user_customization(
		color_picker_button.color,
		eye_color_picker_button.color,
		wings_color_picker.color,
		horns_color_picker.color,
		markings_color_picker.color,
		selected_wings,
		selected_horns,
		selected_markings
	)
	
	if result.has("error"):
		DebugLogger.error("Failed to update customization: " + str(result.error))
	else:
		DebugLogger.log("Customization updated successfully")
	
	hide_ui()


func _on_close_pressed() -> void:
	# Revert UI to original state
	color_picker_button.color = original_state["body_color"]
	eye_color_picker_button.color = original_state["eye_color"]
	wings_color_picker.color = original_state["wing_color"]
	horns_color_picker.color = original_state["horn_color"]
	markings_color_picker.color = original_state["markings_color"]
	selected_wings = original_state["wing_type"]
	selected_horns = original_state["horn_type"]
	selected_markings = original_state["markings_type"]
	_update_all_buttons()
	
	# Emit cancelled signal to restore original state
	cancelled.emit()
	closed.emit()
	hide_ui()


