extends CanvasLayer

signal part_changed(part_name: String)
signal cancelled()

@onready var panel = $Panel
@onready var apply_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/ApplyButton
@onready var close_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton
@onready var lock_colors_checkbox = $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/LockColorsCheckbox

@onready var color_pickers := {
	"Head": $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/HeadColorSection/HeadColorPicker,
	"Body": $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/BodyColorSection/BodyColorPicker,
	"Eyes": $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/EyesColorSection/EyesColorPicker,
	"Tail": $Panel/MarginContainer/VBoxContainer/MainContent/ColorsSection/TailColorSection/TailColorPicker,
	"Wings": $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsColorPicker,
	"Horns": $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsColorPicker
}

@onready var line_type_buttons := {
	"Wings": {
		CustomizationConstants.Wings_Type.NO_WINGS: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/NoWingsButton,
		CustomizationConstants.Wings_Type.CLASSIC: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/Wings1Button,
		CustomizationConstants.Wings_Type.FEATHERED: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/WingsRow/WingsContainer/Wings2Button
	},
	"Horns": {
		CustomizationConstants.Horns_Type.NO_HORNS: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsContainer/NoHornsButton,
		CustomizationConstants.Horns_Type.CLASSIC: $Panel/MarginContainer/VBoxContainer/MainContent/FeaturesSection/FeaturesGrid/HornsRow/HornsContainer/Horns1Button
	}
}

var syncable_body_parts := [ "Head", "Body", "Tail"]

var active_player_customization := {}
var original_state := {}

func _ready() -> void:
	hide_ui()
	
	_connect_buttons()
	_connect_color_pickers()


func _connect_buttons() -> void:
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)
	lock_colors_checkbox.toggled.connect(_on_lock_colors_toggled)
	
	for part_name in line_type_buttons:
		var buttons = line_type_buttons[part_name]
		for line_type in buttons:
			buttons[line_type].pressed.connect(on_line_type_selected.bind(part_name, line_type))

	apply_button.focus_neighbor_right = close_button.get_path()
	close_button.focus_neighbor_left = apply_button.get_path()


func _connect_color_pickers() -> void:
	for part_name in color_pickers:
		if color_pickers[part_name]:
			color_pickers[part_name].color_changed.connect(_on_color_changed.bind(part_name))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel.visible:
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func show_ui(customization_parts: Dictionary) -> void:
	ClientNetworkGlobals.is_movement_blocking_ui_active = true
	lock_colors_checkbox.button_pressed = false
	panel.visible = true
	
	active_player_customization = customization_parts
	original_state = {}
	
	for part_name in customization_parts:
		var part = customization_parts[part_name]	
		_save_original_part(part)
		_set_color_picker_value(part)
		
	_select_line_type_button("Wings")
	_select_line_type_button("Horns")
	
	apply_button.grab_focus()


func _save_original_part(part: PlayerCustomization.Part) -> void:
	original_state[part.name] = {
			"line_type": part.line_type,
			"color": part.color
	}


func _set_color_picker_value(part: PlayerCustomization.Part) -> void:
	color_pickers[part.name].color = part.color


func _select_line_type_button(part_name: String) -> void:
	_update_type_buttons(line_type_buttons[part_name], active_player_customization[part_name].line_type)
	_update_color_picker_visibility(part_name)


func _update_type_buttons(buttons: Dictionary, selected_type: int) -> void:
	for type in buttons:
		if buttons[type]:
			buttons[type].disabled = (type == selected_type)


func _update_color_picker_visibility(part_name: String) -> void:
	color_pickers[part_name].visible = (active_player_customization[part_name].line_type != 0)


func hide_ui() -> void:
	panel.visible = false
	ClientNetworkGlobals.is_movement_blocking_ui_active = false


func on_line_type_selected(part_name: String, line_type: int) -> void:
	active_player_customization[part_name].line_type = line_type
	_update_type_buttons(line_type_buttons[part_name], line_type)
	_update_color_picker_visibility(part_name)
	part_changed.emit(part_name)


func _on_color_changed(color: Color, part_name: String) -> void:
	active_player_customization[part_name].color = color
	
	if lock_colors_checkbox.button_pressed and part_name in syncable_body_parts:
		_sync_locked_colors(color, part_name)
	
	part_changed.emit(part_name)


func _on_lock_colors_toggled(is_pressed: bool) -> void:
	if is_pressed:
		var body_color = active_player_customization["Body"].color
		_sync_locked_colors(body_color, "Body")


func _sync_locked_colors(color: Color, source_part: String) -> void:	
	for part_name in syncable_body_parts:
		if part_name == source_part:
			continue
		
		active_player_customization[part_name].color = color
		color_pickers[part_name].color = color
		part_changed.emit(part_name)


func _on_apply_pressed() -> void:	
	# TODO: Send customization update to API
	# var result = await UserAPI.update_user_customization(...)
	
	DebugLogger.log("Customization updated successfully")
	hide_ui()


func _on_close_pressed() -> void:
	for part_name in original_state:
		active_player_customization[part_name].line_type = original_state[part_name].line_type
		active_player_customization[part_name].color = original_state[part_name].color

	cancelled.emit()
	hide_ui()
