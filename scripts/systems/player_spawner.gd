extends Node

const NETWORK_PLAYER = preload("uid://ifha2oyc3bqr")

var spawn_areas: Dictionary = {}  # label -> Area2D mapping


func _ready() -> void:
	_index_spawn_areas()
	
	NetworkHandler.on_peer_connected.connect(spawn_player)
	ClientNetworkGlobals.handle_local_id_assignment.connect(spawn_player)
	ClientNetworkGlobals.handle_remote_id_assignment.connect(_on_remote_id_assignment)
	ClientNetworkGlobals.handle_player_disconnect.connect(despawn_player)
	ClientNetworkGlobals.handle_player_scene_change.connect(_on_player_scene_change)
	
	_cleanup_existing_players()


func _index_spawn_areas() -> void:
	# Find all Area2D children and index them by their name (label)
	for child in get_children():
		if child is Area2D:
			var label = child.name
			spawn_areas[label] = child
			DebugLogger.log("PlayerSpawner: Indexed spawn area '" + label + "'")
	
	if spawn_areas.is_empty():
		push_error("PlayerSpawner: No spawn areas (Area2D) found!")


func _cleanup_existing_players() -> void:
	# Remove all existing player nodes to avoid duplicates when changing scenes
	for child in get_children():
		if child is CharacterBody2D and child.has_method("get") and child.get("owner_id") != null:
			DebugLogger.log("Cleaning up existing player: " + child.name)
			child.queue_free()
	
	# After cleanup, respawn the local player if we have an ID
	if ClientNetworkGlobals.id != -1:
		DebugLogger.log("Respawning local player with ID: " + str(ClientNetworkGlobals.id))
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
					DebugLogger.log("Respawning remote player with ID: " + str(remote_id) + " (in same scene)")
					call_deferred("spawn_player", remote_id)
				else:
					DebugLogger.log("Skipping remote player with ID: " + str(remote_id) + " (in different scene: " + player_scene + ")")
			else:
				# If we don't know their scene yet, don't spawn them
				# They will be spawned when we receive their scene change notification
				DebugLogger.log("Skipping remote player with ID: " + str(remote_id) + " (scene unknown, waiting for scene change notification)")


func get_spawn_area_for_player(player_id: int) -> Area2D:
	var from_scene_name = ""
	
	# Check if we have a record of where this player came from
	if player_id == ClientNetworkGlobals.id and not ClientNetworkGlobals.previous_scene.is_empty():
		# This is the local player entering from another scene
		var scene_file = ClientNetworkGlobals.previous_scene.get_file().get_basename()
		from_scene_name = _normalize_scene_name(scene_file)
		DebugLogger.log("Local player " + str(player_id) + " came from scene: " + from_scene_name)

	DebugLogger.log("Determining spawn area for player " + str(player_id) + " (from scene: '" + from_scene_name + "')")
	
	# Check if we have a spawn area matching the previous scene
	if not from_scene_name.is_empty() and spawn_areas.has(from_scene_name):
		DebugLogger.log("Using spawn area '" + from_scene_name + "' for player " + str(player_id))
		return spawn_areas[from_scene_name]
	
	# Otherwise use "Default" spawn area
	if spawn_areas.has("Default"):
		DebugLogger.log("Using default spawn area for player " + str(player_id))
		return spawn_areas["Default"]
	
	# Fallback to first available spawn area
	if not spawn_areas.is_empty():
		var first_label = spawn_areas.keys()[0]
		DebugLogger.log("WARNING: No Default spawn area found, using '" + first_label + "' for player " + str(player_id))
		return spawn_areas[first_label]
	
	push_error("PlayerSpawner: No spawn areas available!")
	return null


func _normalize_scene_name(scene_file: String) -> String:
	# Convert scene filename to spawn area label format
	# "level1" -> "Level1", "hub" -> "Hub", etc.
	var normalized = scene_file.capitalize().replace(" ", "")
	return normalized


func get_random_spawn_position(spawn_area: Area2D) -> Vector2:
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
		DebugLogger.log("WARNING: Player " + str(id) + " already exists, skipping spawn")
		return
	
	var player = NETWORK_PLAYER.instantiate() #9
	player.owner_id = id
	player.name = str(id)
	
	# Get appropriate spawn area and position
	var spawn_area = get_spawn_area_for_player(id)
	player.global_position = get_random_spawn_position(spawn_area)
	
	call_deferred("add_child", player)
	DebugLogger.log("Spawned player " + str(id) + " at position: " + str(player.global_position))

func despawn_player(id: int) -> void:
	var player = get_node_or_null(str(id))
	if player:
		DebugLogger.log("Despawning player with ID: " + str(id))
		player.queue_free()
	else:
		DebugLogger.log("WARNING: Could not find player with ID " + str(id) + " to despawn")


func _on_remote_id_assignment(remote_id: int) -> void:
	# Don't spawn remote players immediately on ID assignment
	# Wait for their scene change notification to know if they're in our scene
	DebugLogger.log("Remote ID " + str(remote_id) + " assigned, waiting for scene change notification before spawning")


func _on_player_scene_change(scene_change) -> void:
	var player_id = scene_change.id
	var new_scene = scene_change.scene_path
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	DebugLogger.log("Player " + str(player_id) + " changed to scene: " + new_scene + " (current scene: " + current_scene_path + ")")
	
	# If player left this scene, despawn them
	if new_scene != current_scene_path:
		despawn_player(player_id)
	# If player entered this scene, spawn them
	elif new_scene == current_scene_path and player_id != ClientNetworkGlobals.id:
		spawn_player(player_id)
