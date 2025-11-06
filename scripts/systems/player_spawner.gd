extends Node

const NETWORK_PLAYER = preload("uid://ifha2oyc3bqr")

var spawn_areas: Dictionary = {}  # label -> Area2D mapping
var player_container: Node = null  # The node that holds all players in current scene

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

	ClientNetworkGlobals.handle_local_id_assignment.connect(_on_local_id_assignment)
	ClientNetworkGlobals.handle_player_disconnect.connect(despawn_player)
	ClientNetworkGlobals.handle_player_scene_change.connect(_on_player_scene_change)
	

# Called when a new scene is loaded - find spawn areas and container
func on_scene_ready(scene_root: Node) -> void:
	ClientNetworkGlobals.current_scene = scene_root.scene_file_path
	DebugLogger.log("Scene loaded: " + ClientNetworkGlobals.current_scene + ", Previous scene: " + ClientNetworkGlobals.previous_scene)
	
	player_container = scene_root.find_child("Players", false, false)
	_index_spawn_areas(scene_root)
	
	# If we have an ID assigned, refresh players (this handles scene transitions)
	if ClientNetworkGlobals.id != -1:
		DebugLogger.log("Scene ready with assigned ID, refreshing players")
		_refresh_players()


func _on_node_added(node: Node) -> void:
	if node == get_tree().current_scene:
		on_scene_ready(node)


func _on_local_id_assignment(local_id: int) -> void:
	DebugLogger.log("ID assigned: " + str(local_id) + ", sending username and scene change")
	_send_username(local_id)
	_send_scene_change(local_id, ClientNetworkGlobals.current_scene)
	
	# After ID assignment, spawn the local player and any remote players in the same scene
	_refresh_players()


func _index_spawn_areas(scene_root: Node) -> void:
	spawn_areas.clear()
	
	# Find all Area2D nodes in the scene that are spawn areas
	var areas = _find_all_spawn_areas(scene_root)
	for area in areas:
		if area is Area2D:
			var label = area.name
			spawn_areas[label] = area
			DebugLogger.log("PlayerSpawner: Indexed spawn area '" + label + "'")
	
	if spawn_areas.is_empty():
		push_warning("PlayerSpawner: No spawn areas (Area2D) found in scene!")


func _find_all_spawn_areas(node: Node) -> Array:
	var result = []
	
	# Look for a node specifically named "SpawnAreas"
	var spawn_areas_node = node.find_child("SpawnAreas", false, false)
	if spawn_areas_node:
		for child in spawn_areas_node.get_children():
			if child is Area2D:
				result.append(child)

	return result


func _refresh_players() -> void:
	if player_container == null:
		DebugLogger.log("_refresh_players: player_container is null, skipping")
		return
	
	DebugLogger.log("_refresh_players: Starting refresh. Current scene: " + str(ClientNetworkGlobals.current_scene))
	DebugLogger.log("_refresh_players: Known player scenes: " + str(ClientNetworkGlobals.player_scenes))
	
	# Remove all existing player nodes
	for child in player_container.get_children():
		if child is CharacterBody2D and child.has_method("get") and child.get("owner_id") != null:
			DebugLogger.log("Cleaning up existing player: " + child.name)
			child.queue_free()
	
	# After cleanup, respawn the local player if we have an ID
	if ClientNetworkGlobals.id != -1:
		DebugLogger.log("Respawning local player with ID: " + str(ClientNetworkGlobals.id))
		spawn_player(ClientNetworkGlobals.id)
	
	# Get current scene path
	var current_scene = ClientNetworkGlobals.current_scene
	if current_scene == null:
		DebugLogger.log("_refresh_players: current_scene is null, skipping remote players")
		return

	for player_id in ClientNetworkGlobals.player_scenes:
		if player_id == ClientNetworkGlobals.id:
			continue

		var player_scene = ClientNetworkGlobals.player_scenes[player_id]
		DebugLogger.log("_refresh_players: Checking player " + str(player_id) + " - their scene: " + player_scene + ", current: " + current_scene)
		if player_scene == current_scene:
			DebugLogger.log("Respawning remote player with ID: " + str(player_id) + " (in same scene)")
			spawn_player(player_id)
		else:
			DebugLogger.log("Skipping remote player with ID: " + str(player_id) + " (different scene)")


func get_spawn_area_for_player(player_id: int) -> Area2D:
	if player_id != ClientNetworkGlobals.id:
		return spawn_areas["Remote"]

	var from_scene_name = ""
	
	# Use previous scene name to select spawn area
	if not ClientNetworkGlobals.previous_scene.is_empty():
		var scene_file = ClientNetworkGlobals.previous_scene.get_file().get_basename()
		from_scene_name = _normalize_scene_name(scene_file)
		DebugLogger.log("Local player " + str(player_id) + " came from scene: " + from_scene_name)
		return spawn_areas[from_scene_name]
	
	# Otherwise use "Default" spawn area
	DebugLogger.log("Using default spawn area for player " + str(player_id))
	return spawn_areas["Default"]


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
	if player_container == null:
		DebugLogger.log("WARNING: Cannot spawn player " + str(id) + ", no player container")
		return
	
	# Check if player already exists
	# var existing = player_container.get_node_or_null(str(id))
	# if existing != null:
	# 	DebugLogger.log("WARNING: Player " + str(id) + " already exists, skipping spawn")
	# 	return
	
	var player = NETWORK_PLAYER.instantiate()
	player.owner_id = id
	player.name = str(id)
	
	# Get appropriate spawn area and position
	var spawn_area = get_spawn_area_for_player(id)
	player.global_position = get_random_spawn_position(spawn_area)
	
	player_container.add_child(player)
	DebugLogger.log("Spawned player " + str(id) + " at position: " + str(player.global_position))


func despawn_player(id: int) -> void:
	if player_container == null:
		return
	
	var player = player_container.get_node_or_null(str(id))
	if player:
		DebugLogger.log("Despawning player with ID: " + str(id))
		player.queue_free()
	else:
		DebugLogger.log("WARNING: Could not find player with ID " + str(id) + " to despawn")



func _on_player_scene_change(scene_change) -> void:
	var player_id = scene_change.id
	var new_scene = scene_change.scene_path

	ClientNetworkGlobals.player_scenes[player_id] = new_scene

	DebugLogger.log("Player scenes after update: " + str(ClientNetworkGlobals.player_scenes))

	# Skip handling for local player - they'll be respawned when the scene loads via on_scene_ready()
	if player_id == ClientNetworkGlobals.id:
		DebugLogger.log("Local player scene change detected, waiting for scene load")
		return
	
	# Get current scene path safely
	var current_scene_path = ClientNetworkGlobals.current_scene
	if current_scene_path == null:
		DebugLogger.log("Current scene is null, ignoring scene change for player " + str(player_id))
		return
	
	DebugLogger.log("Player " + str(player_id) + " changed to scene: " + new_scene + " (current scene: " + current_scene_path + ")")
	
	# For remote players, incrementally spawn or despawn based on scene match
	if new_scene != current_scene_path:
		despawn_player(player_id)
	else:
		spawn_player(player_id)


func _send_username(player_id: int) -> void:
	DebugLogger.log("Sending username '" + ClientNetworkGlobals.username + "' for player " + str(player_id))
	PlayerUsername.create(player_id, ClientNetworkGlobals.username).send(NetworkHandler.server_peer)


func _send_scene_change(player_id: int, scene_path: String) -> void:
	DebugLogger.log("Sending scene change for player " + str(player_id) + " to scene " + scene_path)
	PlayerSceneChange.create(player_id, scene_path).send(NetworkHandler.server_peer)
