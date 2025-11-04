extends CanvasLayer
## Player List Overlay - Shows all players in current scene when TAB is pressed

@onready var panel: Panel = $Panel
@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/GridContainer

var is_visible_overlay: bool = false


func _ready() -> void:
	panel.visible = false
	is_visible_overlay = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		toggle_overlay()
		get_viewport().set_input_as_handled()


func toggle_overlay() -> void:
	is_visible_overlay = !is_visible_overlay
	panel.visible = is_visible_overlay
	
	if is_visible_overlay:
		update_player_list()


func update_player_list() -> void:
	# Clear existing labels
	for child in grid_container.get_children():
		child.queue_free()
	
	# Get current scene path
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# Add local player first
	if ClientNetworkGlobals.id != -1:
		var local_username = ClientNetworkGlobals.username
		if local_username.is_empty():
			local_username = "Player"
		_add_player_label(local_username + " (You)")
	
	# Add all remote players in the same scene
	for player_id in ClientNetworkGlobals.remote_ids:
		# Check if player is in the same scene
		if ClientNetworkGlobals.player_scenes.has(player_id):
			var player_scene = ClientNetworkGlobals.player_scenes[player_id]
			if player_scene == current_scene_path:
				# Get username
				var username = ClientNetworkGlobals.player_usernames.get(player_id, "Player")
				_add_player_label(username)
		# If scene unknown, don't show them (they haven't sent scene change yet)


func _add_player_label(username: String) -> void:
	var label = Label.new()
	label.text = username
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(150, 30)
	grid_container.add_child(label)
