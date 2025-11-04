extends Node

signal handle_local_id_assignment(local_id: int)
signal handle_remote_id_assignment(remote_id: int)
signal handle_player_position(player_position: PlayerPosition)
signal handle_player_username(player_username: PlayerUsername)
signal handle_player_disconnect(player_id: int)
signal handle_player_animation(player_animation: PlayerAnimation)
signal handle_player_scene_change(player_scene_change: PlayerSceneChange)
signal balance_changed(new_balance: int)

var id: int = -1
var remote_ids: Array[int]

var username: String = ""
var player_usernames: Dictionary = {} # id -> username mapping

var current_scene: String = ""
var player_scenes: Dictionary = {} # id -> scene_path mapping

var balance: int = 0:
	set(value):
		balance = value
		balance_changed.emit(balance)


func _ready() -> void:
	NetworkHandler.on_client_packet.connect(on_client_packet)
	
	
func on_client_packet(data: PackedByteArray) -> void:
	var packet_type: int = data.decode_u8(0)
	
	match packet_type:
		PacketInfo.PACKET_TYPE.ID_ASSIGNMENT:
			manage_ids(IDAssignment.create_from_data(data))
				
		PacketInfo.PACKET_TYPE.PLAYER_POSITION:
			handle_player_position.emit(PlayerPosition.create_from_data(data))
			
		PacketInfo.PACKET_TYPE.PLAYER_USERNAME:
			var player_username = PlayerUsername.create_from_data(data) #12
			print("ClientNetworkGlobals received username packet - ID: ", player_username.id, " Username: ", player_username.username)
			player_usernames[player_username.id] = player_username.username
			handle_player_username.emit(player_username)
			
		PacketInfo.PACKET_TYPE.PLAYER_DISCONNECT:
			var player_disconnect = PlayerDisconnect.create_from_data(data)
			print("ClientNetworkGlobals received disconnect for ID: ", player_disconnect.id)
			var disconnected_id = player_disconnect.id
			remote_ids.erase(disconnected_id)
			player_usernames.erase(disconnected_id)
			player_scenes.erase(disconnected_id)
			handle_player_disconnect.emit(disconnected_id)

		PacketInfo.PACKET_TYPE.PLAYER_ANIMATION:
			var player_anim = PlayerAnimation.create_from_data(data)
			handle_player_animation.emit(player_anim)
			
		PacketInfo.PACKET_TYPE.PLAYER_SCENE_CHANGE:
			var scene_change = PlayerSceneChange.create_from_data(data)
			print("ClientNetworkGlobals received scene change - ID: ", scene_change.id, " Scene: ", scene_change.scene_path)
			player_scenes[scene_change.id] = scene_change.scene_path
			handle_player_scene_change.emit(scene_change)
		_:
			push_error("Packet type with index ", data[0], " unhandled.")


func manage_ids(id_assignment: IDAssignment) -> void:
	if id == -1:
		id = id_assignment.id
		handle_local_id_assignment.emit(id_assignment.id) #8
		
		remote_ids = id_assignment.remoted_ids
		for remote_id in remote_ids:
			if remote_id == id: continue
			handle_remote_id_assignment.emit(remote_id)
	
	else:
		remote_ids.append(id_assignment.id)
		handle_remote_id_assignment.emit(id_assignment.id)
