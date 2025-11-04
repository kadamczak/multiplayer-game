extends Node

signal handle_player_position(peer_id: int, player_position: PlayerPosition)

var peer_ids: Array[int]
var peer_usernames: Dictionary = {} # peer_id -> username mapping
var peer_scenes: Dictionary = {} # peer_id -> scene_path mapping

func _ready() -> void:
	NetworkHandler.on_peer_connected.connect(on_peer_connected)
	NetworkHandler.on_peer_disconnected.connect(on_peer_disconnected)
	NetworkHandler.on_server_packet.connect(on_server_packet)
	

func on_peer_connected(peer_id: int) -> void:
	peer_ids.append(peer_id) #7
	IDAssignment.create(peer_id, peer_ids).broadcast(NetworkHandler.connection)
	
	# Send all existing usernames to the new client
	for existing_peer_id in peer_usernames:
		var username = peer_usernames[existing_peer_id]
		DebugLogger.log("Sending existing username to new client: ID " + str(existing_peer_id) + " -> " + username)
		PlayerUsername.create(existing_peer_id, username).send(NetworkHandler.client_peers[peer_id])
	
	# Send all existing scenes to the new client
	for existing_peer_id in peer_scenes:
		var scene_path = peer_scenes[existing_peer_id]
		DebugLogger.log("Sending existing scene to new client: ID " + str(existing_peer_id) + " -> " + scene_path)
		PlayerSceneChange.create(existing_peer_id, scene_path).send(NetworkHandler.client_peers[peer_id])
	
func on_peer_disconnected(peer_id: int) -> void:
	peer_ids.erase(peer_id)
	peer_usernames.erase(peer_id)
	peer_scenes.erase(peer_id)
	# Notify all clients that this player disconnected
	DebugLogger.log("Broadcasting disconnect for peer " + str(peer_id))
	PlayerDisconnect.create(peer_id).broadcast(NetworkHandler.connection)
	
# Server only sends IDAssignment packets, does not receive them.	
func on_server_packet(peer_id: int, data: PackedByteArray) -> void:
	var packet_type: int = data.decode_u8(0)
	match packet_type:
		PacketInfo.PACKET_TYPE.PLAYER_POSITION:
			handle_player_position.emit(peer_id, PlayerPosition.create_from_data(data))
			
		PacketInfo.PACKET_TYPE.PLAYER_USERNAME: #11
			# Store and broadcast the username to all clients
			var player_username = PlayerUsername.create_from_data(data)
			DebugLogger.log("Server received username from peer " + str(peer_id) + " - ID: " + str(player_username.id) + " Username: " + player_username.username)
			peer_usernames[player_username.id] = player_username.username
			DebugLogger.log("Broadcasting to all clients")
			player_username.broadcast(NetworkHandler.connection)
			
		PacketInfo.PACKET_TYPE.PLAYER_ANIMATION:
			# Broadcast animation state to all clients
			var player_anim = PlayerAnimation.create_from_data(data)
			player_anim.broadcast(NetworkHandler.connection)
			
		PacketInfo.PACKET_TYPE.PLAYER_SCENE_CHANGE:
			# Store and broadcast scene change to all clients
			var scene_change = PlayerSceneChange.create_from_data(data)
			DebugLogger.log("Server received scene change from peer " + str(peer_id) + " - ID: " + str(scene_change.id) + " Scene: " + scene_change.scene_path)
			peer_scenes[scene_change.id] = scene_change.scene_path
			DebugLogger.log("Broadcasting to all clients")
			scene_change.broadcast(NetworkHandler.connection)
		_:
			push_error("Packet type with index ", data[0], " unhandled.")
