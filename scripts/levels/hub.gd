extends Node2D
## Hub scene script - handles post-login initialization

func _ready() -> void:
	# Connect to ID assignment if not already connected
	if not ClientNetworkGlobals.handle_local_id_assignment.is_connected(_on_local_id_assigned):
		ClientNetworkGlobals.handle_local_id_assignment.connect(_on_local_id_assigned)
	
	# If we already have an ID (reconnecting), send username immediately
	if ClientNetworkGlobals.id != -1 and not ClientNetworkGlobals.username.is_empty():
		_send_username(ClientNetworkGlobals.id)


func _on_local_id_assigned(local_id: int) -> void:
	print("Hub: ID assigned: ", local_id, ", sending username: ", ClientNetworkGlobals.username)
	_send_username(local_id)


func _send_username(player_id: int) -> void:
	if ClientNetworkGlobals.username.is_empty():
		push_warning("Hub: Username is empty, cannot send")
		return
	
	if NetworkHandler.server_peer == null:
		push_warning("Hub: Server peer is null, cannot send username")
		return
	
	print("Hub: Sending username '", ClientNetworkGlobals.username, "' for player ", player_id)
	PlayerUsername.create(player_id, ClientNetworkGlobals.username).send(NetworkHandler.server_peer)
