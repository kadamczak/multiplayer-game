class_name PlayerUsername
extends PacketInfo

var id: int
var username: String

static func create(player_id: int, player_name: String) -> PlayerUsername:
	var player_username = PlayerUsername.new()
	player_username.packet_type = PacketInfo.PACKET_TYPE.PLAYER_USERNAME
	player_username.flag = ENetPacketPeer.FLAG_RELIABLE
	player_username.id = player_id
	player_username.username = player_name
	return player_username

static func create_from_data(data: PackedByteArray) -> PlayerUsername:
	var player_username = PlayerUsername.new()
	player_username.decode(data)
	return player_username

func encode() -> PackedByteArray:
	var data = super.encode()
	data.resize(2)
	data.encode_u8(1, id)
	data.append_array(username.to_utf8_buffer())
	print("PlayerUsername.encode() - ID: ", id, " Username: ", username, " Data size: ", data.size())
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)
	username = data.slice(2).get_string_from_utf8()
	print("PlayerUsername.decode() - ID: ", id, " Username: ", username, " Data size: ", data.size())
