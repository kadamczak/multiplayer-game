extends Node

const NETWORK_PLAYER = preload("uid://ifha2oyc3bqr")

@onready var spawn_area = $Area2D


func _ready() -> void:
	NetworkHandler.on_peer_connected.connect(spawn_player)
	ClientNetworkGlobals.handle_local_id_assignment.connect(spawn_player)
	ClientNetworkGlobals.handle_remote_id_assignment.connect(_on_remote_id_assignment)
	ClientNetworkGlobals.handle_player_disconnect.connect(despawn_player)
	ClientNetworkGlobals.handle_player_scene_change.connect(_on_player_scene_change)
	
	# Clean up any existing player instances from previous scene
	_cleanup_existing_players()


func _cleanup_existing_players() -> void:
	# Remove all existing player nodes to avoid duplicates when changing scenes
	for child in get_children():
		if child is CharacterBody2D and child.has_method("get") and child.get("owner_id") != null:
			print("Cleaning up existing player: ", child.name)
			child.queue_free()
	
	# After cleanup, respawn the local player if we have an ID
	if ClientNetworkGlobals.id != -1:
		print("Respawning local player with ID: ", ClientNetworkGlobals.id)
		call_deferred("spawn_player", ClientNetworkGlobals.id)
	
	# Get current scene path
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# Also respawn all remote players that are in the same scene
	for remote_id in ClientNetworkGlobals.remote_ids:
		if remote_id != ClientNetworkGlobals.id:
			# Check if we know this player's scene
			if ClientNetworkGlobals.player_scenes.has(remote_id):
				var player_scene = ClientNetworkGlobals.player_scenes[remote_id]
				if player_scene == current_scene_path:
					print("Respawning remote player with ID: ", remote_id, " (in same scene)")
					call_deferred("spawn_player", remote_id)
				else:
					print("Skipping remote player with ID: ", remote_id, " (in different scene: ", player_scene, ")")
			else:
				# If we don't know their scene yet, don't spawn them
				# They will be spawned when we receive their scene change notification
				print("Skipping remote player with ID: ", remote_id, " (scene unknown, waiting for scene change notification)")


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
	# Check if player already exists
	if get_node_or_null(str(id)) != null:
		print("WARNING: Player ", id, " already exists, skipping spawn")
		return
	
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


func _on_remote_id_assignment(remote_id: int) -> void:
	# Don't spawn remote players immediately on ID assignment
	# Wait for their scene change notification to know if they're in our scene
	print("Remote ID ", remote_id, " assigned, waiting for scene change notification before spawning")


func _on_player_scene_change(scene_change) -> void:
	var player_id = scene_change.id
	var new_scene = scene_change.scene_path
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	print("Player ", player_id, " changed to scene: ", new_scene, " (current scene: ", current_scene_path, ")")
	
	# If player left this scene, despawn them
	if new_scene != current_scene_path:
		despawn_player(player_id)
	# If player entered this scene, spawn them
	elif new_scene == current_scene_path and player_id != ClientNetworkGlobals.id:
		spawn_player(player_id)
