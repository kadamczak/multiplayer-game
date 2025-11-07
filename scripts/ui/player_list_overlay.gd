extends CanvasLayer
## Player List Overlay - Shows all players in current scene when TAB is pressed

@onready var panel: Panel = $Panel
@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/GridContainer

var is_visible_overlay: bool = false


func _ready() -> void:
	panel.visible = false
	is_visible_overlay = false


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_toggle_playerlist"):
		toggle_overlay()
		get_viewport().set_input_as_handled()


func toggle_overlay() -> void:
	is_visible_overlay = !is_visible_overlay
	panel.visible = is_visible_overlay
	
	if is_visible_overlay:
		update_player_list()

func _add_player_label(username: String) -> void:
	var label = Label.new()
	label.text = username
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(150, 30)
	grid_container.add_child(label)


func update_player_list() -> void:
	# Clear existing labels
	for child in grid_container.get_children():
		child.queue_free()

	var current_scene_path = get_tree().current_scene.scene_file_path
	var local_id = ClientNetworkGlobals.id
	
	# Add local player first
	if local_id != -1:
		var local_username = ClientNetworkGlobals.username
		if local_username.is_empty():
			local_username = "Player"
		_add_player_label(local_username + " (You)")

	# Add other players
	for player_id in ClientNetworkGlobals.player_scenes:
		if player_id == local_id:
			continue

		var player_scene_path = ClientNetworkGlobals.player_scenes[player_id]
		if player_scene_path == current_scene_path:
			var username = ClientNetworkGlobals.player_usernames.get(player_id, "Player")
			_add_player_label(username)
