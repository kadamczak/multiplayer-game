extends CanvasLayer

signal color_applied(color: Color)
signal eye_color_applied(eye_color: Color)
signal wings_changed(wing_type: int)  # 0 = none, 1 = wings1, 2 = wings2
signal wings_color_applied(color: Color)
signal horns_changed(horn_type: int)  # 0 = none, 1 = horns1
signal horns_color_applied(color: Color)
signal markings_changed(markings_type: int)  # 0 = none, 1 = markings1, 2 = markings2
signal markings_color_applied(color: Color)
signal cancelled()
signal closed()

@onready var panel = $Panel
@onready var color_picker_button = $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/BodyColorSection/ColorPickerButton
@onready var eye_color_picker_button = $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/EyeColorSection/EyeColorPickerButton
@onready var no_wings_button = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/NoWingsButton
@onready var wings1_button = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/Wings1Button
@onready var wings2_button = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/Wings2Button
@onready var wings_color_picker = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsColorPicker
@onready var no_horns_button = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsContainer/NoHornsButton
@onready var horns1_button = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsContainer/Horns1Button
@onready var horns_color_picker = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsColorPicker
@onready var no_markings_button = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/MarkingsRow/MarkingsContainer/NoMarkingsButton
@onready var markings1_button = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/MarkingsRow/MarkingsContainer/Markings1Button
@onready var markings2_button = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/MarkingsRow/MarkingsContainer/Markings2Button
@onready var markings_color_picker = $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/MarkingsRow/MarkingsColorPicker
@onready var apply_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/ApplyButton
@onready var close_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton

var selected_wings: int = 1  # Default to Wings 1
var selected_horns: int = 1  # Default to Horns 1
var selected_markings: int = 0  # Default to No Markings

# Store original state for cancel functionality
var original_body_color: Color = Color.WHITE
var original_eye_color: Color = Color.WHITE
var original_wing_type: int = 1
var original_wing_color: Color = Color.WHITE
var original_horn_type: int = 1
var original_horn_color: Color = Color.WHITE
var original_markings_type: int = 0
var original_markings_color: Color = Color.WHITE

func _ready() -> void:
	hide_ui()
	
	# Connect signals
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)
	no_wings_button.pressed.connect(_on_no_wings_pressed)
	wings1_button.pressed.connect(_on_wings1_pressed)
	wings2_button.pressed.connect(_on_wings2_pressed)
	no_horns_button.pressed.connect(_on_no_horns_pressed)
	horns1_button.pressed.connect(_on_horns1_pressed)
	no_markings_button.pressed.connect(_on_no_markings_pressed)
	markings1_button.pressed.connect(_on_markings1_pressed)
	markings2_button.pressed.connect(_on_markings2_pressed)
	
	# Connect color picker changes for real-time preview
	color_picker_button.color_changed.connect(_on_body_color_changed)
	eye_color_picker_button.color_changed.connect(_on_eye_color_changed)
	wings_color_picker.color_changed.connect(_on_wings_color_changed)
	horns_color_picker.color_changed.connect(_on_horns_color_changed)
	markings_color_picker.color_changed.connect(_on_markings_color_changed)
	
	# Set up focus navigation
	apply_button.focus_neighbor_right = close_button.get_path()
	close_button.focus_neighbor_left = apply_button.get_path()
	
	# Update button states
	_update_wings_buttons()
	_update_horns_buttons()
	_update_markings_buttons()
	_update_color_pickers_visibility()



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel.visible:
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func show_ui(current_color: Color = Color.WHITE, current_eye_color: Color = Color.WHITE) -> void:
	panel.visible = true
	color_picker_button.color = current_color
	eye_color_picker_button.color = current_eye_color
	
	# Store original state for cancel functionality
	original_body_color = current_color
	original_eye_color = current_eye_color
	original_wing_type = selected_wings
	original_wing_color = wings_color_picker.color
	original_horn_type = selected_horns
	original_horn_color = horns_color_picker.color
	original_markings_type = selected_markings
	original_markings_color = markings_color_picker.color
	
	ClientNetworkGlobals.is_movement_blocking_ui_active = true
	apply_button.grab_focus()

func hide_ui() -> void:
	panel.visible = false
	if not ClientNetworkGlobals.is_movement_blocking_ui_active:
		return
	# Only clear movement blocking if no other UI is visible
	ClientNetworkGlobals.is_movement_blocking_ui_active = false

func _update_wings_buttons() -> void:
	# Reset all buttons
	no_wings_button.disabled = false
	wings1_button.disabled = false
	wings2_button.disabled = false
	
	# Highlight selected button
	match selected_wings:
		0:
			no_wings_button.disabled = true
		1:
			wings1_button.disabled = true
		2:
			wings2_button.disabled = true
	
	_update_color_pickers_visibility()

func _on_no_wings_pressed() -> void:
	selected_wings = 0
	_update_wings_buttons()
	wings_changed.emit(0)

func _on_wings1_pressed() -> void:
	selected_wings = 1
	_update_wings_buttons()
	wings_changed.emit(1)

func _on_wings2_pressed() -> void:
	selected_wings = 2
	_update_wings_buttons()
	wings_changed.emit(2)

func _update_horns_buttons() -> void:
	# Reset all buttons
	no_horns_button.disabled = false
	horns1_button.disabled = false
	
	# Highlight selected button
	match selected_horns:
		0:
			no_horns_button.disabled = true
		1:
			horns1_button.disabled = true
	
	_update_color_pickers_visibility()

func _on_no_horns_pressed() -> void:
	selected_horns = 0
	_update_horns_buttons()
	horns_changed.emit(0)

func _on_horns1_pressed() -> void:
	selected_horns = 1
	_update_horns_buttons()
	horns_changed.emit(1)

func _update_markings_buttons() -> void:
	# Reset all buttons
	no_markings_button.disabled = false
	markings1_button.disabled = false
	markings2_button.disabled = false
	
	# Highlight selected button
	match selected_markings:
		0:
			no_markings_button.disabled = true
		1:
			markings1_button.disabled = true
		2:
			markings2_button.disabled = true
	
	_update_color_pickers_visibility()

func _on_no_markings_pressed() -> void:
	selected_markings = 0
	_update_markings_buttons()
	markings_changed.emit(0)

func _on_markings1_pressed() -> void:
	selected_markings = 1
	_update_markings_buttons()
	markings_changed.emit(1)

func _on_markings2_pressed() -> void:
	selected_markings = 2
	_update_markings_buttons()
	markings_changed.emit(2)

func _on_body_color_changed(color: Color) -> void:
	color_applied.emit(color)

func _on_eye_color_changed(eye_color: Color) -> void:
	eye_color_applied.emit(eye_color)

func _on_wings_color_changed(color: Color) -> void:
	wings_color_applied.emit(color)

func _on_horns_color_changed(color: Color) -> void:
	horns_color_applied.emit(color)

func _on_markings_color_changed(color: Color) -> void:
	markings_color_applied.emit(color)

func _update_color_pickers_visibility() -> void:
	# Show/hide color pickers based on feature selection
	wings_color_picker.visible = (selected_wings > 0)
	horns_color_picker.visible = (selected_horns > 0)
	markings_color_picker.visible = (selected_markings > 0)

func _on_apply_pressed() -> void:
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
	color_picker_button.color = original_body_color
	eye_color_picker_button.color = original_eye_color
	wings_color_picker.color = original_wing_color
	horns_color_picker.color = original_horn_color
	markings_color_picker.color = original_markings_color
	selected_wings = original_wing_type
	selected_horns = original_horn_type
	selected_markings = original_markings_type
	_update_wings_buttons()
	_update_horns_buttons()
	_update_markings_buttons()
	
	# Emit cancelled signal to restore original state
	cancelled.emit()
	closed.emit()
	hide_ui()


