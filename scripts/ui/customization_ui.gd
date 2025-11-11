extends CanvasLayer

signal color_applied(color: Color)
signal closed()

@onready var panel = $Panel
@onready var color_picker_button = $Panel/MarginContainer/VBoxContainer/ColorPickerButton
@onready var apply_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/ApplyButton
@onready var close_button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/CloseButton

func _ready() -> void:
	hide_ui()
	
	# Connect signals
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Set up focus navigation
	apply_button.focus_neighbor_right = close_button.get_path()
	close_button.focus_neighbor_left = apply_button.get_path()

func show_ui(current_color: Color = Color.WHITE) -> void:
	panel.visible = true
	color_picker_button.color = current_color
	ClientNetworkGlobals.is_movement_blocking_ui_active = true
	apply_button.grab_focus()

func hide_ui() -> void:
	panel.visible = false
	if not ClientNetworkGlobals.is_movement_blocking_ui_active:
		return
	# Only clear movement blocking if no other UI is visible
	ClientNetworkGlobals.is_movement_blocking_ui_active = false

func _on_apply_pressed() -> void:
	color_applied.emit(color_picker_button.color)
	hide_ui()

func _on_close_pressed() -> void:
	closed.emit()
	hide_ui()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel.visible:
		_on_close_pressed()
		get_viewport().set_input_as_handled()
