class_name PlayerAnimation
extends PacketInfo

var id: int
var animation_name: String
var flip_h: bool

static func create(player_id: int, anim_name: String, is_flipped: bool) -> PlayerAnimation:
	var player_anim = PlayerAnimation.new()
	player_anim.packet_type = PacketInfo.PACKET_TYPE.PLAYER_ANIMATION
	player_anim.flag = ENetPacketPeer.FLAG_UNSEQUENCED
	player_anim.id = player_id
	player_anim.animation_name = anim_name
	player_anim.flip_h = is_flipped
	return player_anim

static func create_from_data(data: PackedByteArray) -> PlayerAnimation:
	var player_anim = PlayerAnimation.new()
	player_anim.decode(data)
	return player_anim

func encode() -> PackedByteArray:
	var data = super.encode()
	data.resize(3)
	data.encode_u8(1, id)
	data.encode_u8(2, 1 if flip_h else 0)
	data.append_array(animation_name.to_utf8_buffer())
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	id = data.decode_u8(1)
	flip_h = data.decode_u8(2) == 1
	animation_name = data.slice(3).get_string_from_utf8()
