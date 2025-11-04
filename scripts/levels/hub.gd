extends Node2D
## Hub scene script - handles post-login initialization

func _ready() -> void:
	print("Hub scene loaded")
	
	# Update current scene tracking
	var scene_path = get_tree().current_scene.scene_file_path
	ClientNetworkGlobals.current_scene = scene_path
	
	# Connect to ID assignment if not already connected
	if not ClientNetworkGlobals.handle_local_id_assignment.is_connected(_on_local_id_assigned):
		ClientNetworkGlobals.handle_local_id_assignment.connect(_on_local_id_assigned)
	
	# If we already have an ID (coming from another scene), send username and scene change
	if ClientNetworkGlobals.id != -1 and not ClientNetworkGlobals.username.is_empty():
		print("Hub: Player already has ID ", ClientNetworkGlobals.id, ", sending username and scene change")
		_send_username(ClientNetworkGlobals.id)
		_send_scene_change(ClientNetworkGlobals.id, scene_path)


func _on_local_id_assigned(local_id: int) -> void:
	print("Hub: ID assigned: ", local_id, ", sending username and scene change")
	_send_username(local_id)
	var scene_path = get_tree().current_scene.scene_file_path
	_send_scene_change(local_id, scene_path)


func _send_username(player_id: int) -> void:
	if ClientNetworkGlobals.username.is_empty():
		push_warning("Hub: Username is empty, cannot send")
		return
	
	if NetworkHandler.server_peer == null:
		push_warning("Hub: Server peer is null, cannot send username")
		return
	
	print("Hub: Sending username '", ClientNetworkGlobals.username, "' for player ", player_id)
	PlayerUsername.create(player_id, ClientNetworkGlobals.username).send(NetworkHandler.server_peer)


func _send_scene_change(player_id: int, scene_path: String) -> void:
	if NetworkHandler.server_peer == null:
		push_warning("Hub: Server peer is null, cannot send scene change")
		return
	
	print("Hub: Sending scene change for player ", player_id, " to scene ", scene_path)
	PlayerSceneChange.create(player_id, scene_path).send(NetworkHandler.server_peer)
