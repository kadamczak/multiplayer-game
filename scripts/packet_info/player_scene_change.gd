class_name PlayerSceneChange extends PacketInfo

var id: int
var scene_path: String

static func create(player_id: int, player_scene_path: String) -> PlayerSceneChange:
	var scene_change = PlayerSceneChange.new()
	scene_change.packet_type = PacketInfo.PACKET_TYPE.PLAYER_SCENE_CHANGE
	scene_change.flag = ENetPacketPeer.FLAG_RELIABLE
	scene_change.id = player_id
	scene_change.scene_path = player_scene_path
	return scene_change
	
static func create_from_data(data: PackedByteArray) -> PlayerSceneChange:
	var scene_change = PlayerSceneChange.new()
	scene_change.decode(data)
	return scene_change

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	var scene_bytes = scene_path.to_utf8_buffer()
	var scene_length = scene_bytes.size()
	
	data.resize(3 + scene_length)
	data.encode_u8(1, id)
	data.encode_u8(2, scene_length)
	
	for i in range(scene_length):
		data[3 + i] = scene_bytes[i]
	
	return data
	
func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)
	var scene_length = data.decode_u8(2)
	
	var scene_bytes = data.slice(3, 3 + scene_length)
	scene_path = scene_bytes.get_string_from_utf8()
