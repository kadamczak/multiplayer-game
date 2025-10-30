extends Node

const NETWORK_PLAYER = preload("uid://ifha2oyc3bqr")


func _ready() -> void:
	NetworkHandler.on_peer_connected.connect(spawn_player)
	ClientNetworkGlobals.handle_local_id_assignment.connect(spawn_player)
	ClientNetworkGlobals.handle_remote_id_assignment.connect(spawn_player)
	ClientNetworkGlobals.handle_player_disconnect.connect(despawn_player)


func spawn_player(id: int) -> void:
	var player = NETWORK_PLAYER.instantiate() #9
	player.owner_id = id
	player.name = str(id)
	call_deferred("add_child", player)

func despawn_player(id: int) -> void:
	var player = get_node_or_null(str(id))
	if player:
		print("Despawning player with ID: ", id)
		player.queue_free()
	else:
		print("WARNING: Could not find player with ID ", id, " to despawn")
