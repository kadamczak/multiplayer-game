extends Node

const NETWORK_PLAYER = preload("uid://ifha2oyc3bqr")

@onready var spawn_area = $Area2D


func _ready() -> void:
	NetworkHandler.on_peer_connected.connect(spawn_player)
	ClientNetworkGlobals.handle_local_id_assignment.connect(spawn_player)
	ClientNetworkGlobals.handle_remote_id_assignment.connect(spawn_player)
	ClientNetworkGlobals.handle_player_disconnect.connect(despawn_player)


func get_random_spawn_position() -> Vector2:
	if not spawn_area:
		return Vector2.ZERO
	
	var collision_shape = spawn_area.get_node("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		return Vector2.ZERO
	
	var shape = collision_shape.shape
	if shape is RectangleShape2D:
		var rect_shape = shape as RectangleShape2D
		var size = rect_shape.size
		
		# Get random position within the rectangle
		var random_x = randf_range(-size.x / 2, size.x / 2)
		var random_y = randf_range(-size.y / 2, size.y / 2)
		
		# Apply the Area2D position and CollisionShape2D position offsets
		var spawn_pos = spawn_area.global_position + collision_shape.position + Vector2(random_x, random_y)
		return spawn_pos
	
	return Vector2.ZERO


func spawn_player(id: int) -> void:
	var player = NETWORK_PLAYER.instantiate() #9
	player.owner_id = id
	player.name = str(id)
	player.global_position = get_random_spawn_position()
	call_deferred("add_child", player)
	print("Spawned player ", id, " at position: ", player.global_position)

func despawn_player(id: int) -> void:
	var player = get_node_or_null(str(id))
	if player:
		print("Despawning player with ID: ", id)
		player.queue_free()
	else:
		print("WARNING: Could not find player with ID ", id, " to despawn")
