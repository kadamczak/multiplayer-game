extends Node2D
## Level1 scene script - handles multiplayer functionality.

@onready var player_list_panel = $PlayerListOverlay/Panel
@onready var grid_container = $PlayerListOverlay/Panel/MarginContainer/VBoxContainer/GridContainer

var is_player_list_visible: bool = false


func _ready() -> void:
	print("Level1 scene loaded")
	
	# Update current scene tracking
	var scene_path = get_tree().current_scene.scene_file_path
	ClientNetworkGlobals.current_scene = scene_path
	
	# Connect to ID assignment if not already connected
	if not ClientNetworkGlobals.handle_local_id_assignment.is_connected(_on_local_id_assigned):
		ClientNetworkGlobals.handle_local_id_assignment.connect(_on_local_id_assigned)
	
	# If we already have an ID (coming from another scene), send username and scene change
	if ClientNetworkGlobals.id != -1 and not ClientNetworkGlobals.username.is_empty():
		print("Level1: Player already has ID ", ClientNetworkGlobals.id, ", sending username and scene change")
		_send_username(ClientNetworkGlobals.id)
		_send_scene_change(ClientNetworkGlobals.id, scene_path)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		toggle_player_list()
		get_viewport().set_input_as_handled()


func toggle_player_list() -> void:
	is_player_list_visible = !is_player_list_visible
	player_list_panel.visible = is_player_list_visible
	
	if is_player_list_visible:
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


func _add_player_label(username: String) -> void:
	var label = Label.new()
	label.text = username
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(150, 30)
	grid_container.add_child(label)


func _on_local_id_assigned(local_id: int) -> void:
	print("Level1: ID assigned: ", local_id, ", sending username and scene change")
	_send_username(local_id)
	var scene_path = get_tree().current_scene.scene_file_path
	_send_scene_change(local_id, scene_path)


func _send_username(player_id: int) -> void:
	if ClientNetworkGlobals.username.is_empty():
		push_warning("Level1: Username is empty, cannot send")
		return
	
	if NetworkHandler.server_peer == null:
		push_warning("Level1: Server peer is null, cannot send username")
		return
	
	print("Level1: Sending username '", ClientNetworkGlobals.username, "' for player ", player_id)
	PlayerUsername.create(player_id, ClientNetworkGlobals.username).send(NetworkHandler.server_peer)

func _send_scene_change(player_id: int, scene_path: String) -> void:
	if NetworkHandler.server_peer == null:
		push_warning("Level1: Server peer is null, cannot send scene change")
		return
	
	print("Level1: Sending scene change for player ", player_id, " to scene ", scene_path)
	PlayerSceneChange.create(player_id, scene_path).send(NetworkHandler.server_peer)
