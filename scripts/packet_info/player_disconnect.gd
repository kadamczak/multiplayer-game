class_name PlayerDisconnect
extends PacketInfo

var id: int

static func create(player_id: int) -> PlayerDisconnect:
	var player_disconnect = PlayerDisconnect.new()
	player_disconnect.packet_type = PacketInfo.PACKET_TYPE.PLAYER_DISCONNECT
	player_disconnect.flag = ENetPacketPeer.FLAG_RELIABLE
	player_disconnect.id = player_id
	return player_disconnect

static func create_from_data(data: PackedByteArray) -> PlayerDisconnect:
	var player_disconnect = PlayerDisconnect.new()
	player_disconnect.decode(data)
	return player_disconnect

func encode() -> PackedByteArray:
	var data = super.encode()
	data.resize(2)
	data.encode_u8(1, id)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)
