class_name PlayerEquippedItems extends PacketInfo

var player_id: int
var equipped_head_item_id: int
var equipped_body_item_id: int

static func create(id: int, head_item_id: int, body_item_id: int) -> PlayerEquippedItems:
	var info: PlayerEquippedItems = PlayerEquippedItems.new()
	info.packet_type = PACKET_TYPE.PLAYER_EQUIPPED_ITEMS
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.player_id = id
	info.equipped_head_item_id = head_item_id
	info.equipped_body_item_id = body_item_id
	return info

static func create_from_data(data: PackedByteArray) -> PlayerEquippedItems:
	var info: PlayerEquippedItems = PlayerEquippedItems.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	# 1 byte type + 1 byte player_id + 4 bytes head_item_id + 4 bytes body_item_id = 10 bytes
	data.resize(10)
	
	data.encode_u8(1, player_id)
	data.encode_u32(2, equipped_head_item_id)
	data.encode_u32(6, equipped_body_item_id)
	
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	player_id = data.decode_u8(1)
	equipped_head_item_id = data.decode_u32(2)
	equipped_body_item_id = data.decode_u32(6)
