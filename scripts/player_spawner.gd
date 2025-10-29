extends Node

const NETWORK_PLAYER = preload("uid://ifha2oyc3bqr")


func _ready() -> void:
	NetworkHandler.on_peer_connected.connect(spawn_player)
	ClientNetworkGlobals.handle_local_id_assignment.connect(spawn_player)
	ClientNetworkGlobals.handle_remote_id_assignment.connect(spawn_player)


func spawn_player(id: int) -> void:
	var player = NETWORK_PLAYER.instantiate()
	player.owner_id = id
	player.name = str(id)
	call_deferred("add_child", player)
