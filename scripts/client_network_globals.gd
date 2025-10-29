extends Node

signal handle_local_id_assignment(local_id: int)
signal handle_remote_id_assignment(remote_id: int)
signal handle_player_position(player_position: PlayerPosition)
signal handle_player_username(player_username: PlayerUsername)

var id: int = -1
var remote_ids: Array[int]
var username: String = ""
var player_usernames: Dictionary = {} # id -> username mapping


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
			var player_username = PlayerUsername.create_from_data(data)
			print("ClientNetworkGlobals received username packet - ID: ", player_username.id, " Username: ", player_username.username)
			player_usernames[player_username.id] = player_username.username
			handle_player_username.emit(player_username)
		_:
			push_error("Packet type with index ", data[0], " unhandled.")


func manage_ids(id_assignment: IDAssignment) -> void:
	if id == -1:
		id = id_assignment.id
		handle_local_id_assignment.emit(id_assignment.id)
		
		remote_ids = id_assignment.remoted_ids
		for remote_id in remote_ids:
			if remote_id == id: continue
			handle_remote_id_assignment.emit(remote_id)
	
	else:
		remote_ids.append(id_assignment.id)
		handle_remote_id_assignment.emit(id_assignment.id)
