class_name PlayerCustomizationPacket extends PacketInfo

const PART_NAMES = ["Head", "Body", "Tail", "Eyes", "Wings", "Horns", "Markings"]

var player_id: int
var colors: Dictionary = {}
var types: Dictionary = {}

static func create(id: int, customization: Dictionary) -> PlayerCustomizationPacket:
	var info: PlayerCustomizationPacket = PlayerCustomizationPacket.new()
	info.packet_type = PACKET_TYPE.PLAYER_CUSTOMIZATION
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.player_id = id
	
	# Extract colors and types from customization dictionary
	for part_name in PART_NAMES:
		if part_name in customization:
			var part = customization[part_name]
			info.colors[part_name] = part.color
			info.types[part_name] = part.line_type
	
	return info

static func create_from_data(data: PackedByteArray) -> PlayerCustomizationPacket:
	var info: PlayerCustomizationPacket = PlayerCustomizationPacket.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data: PackedByteArray = super.encode()
	# 1 byte type + 1 byte id + (7 parts * (12 bytes color + 1 byte type)) = 1 + 1 + 91 = 93 bytes
	data.resize(93)
	
	data.encode_u8(1, player_id)
	
	var offset = 2
	for part_name in PART_NAMES:
		var color: Color = colors.get(part_name, Color.WHITE)
		var type: int = types.get(part_name, 1)
		
		# Encode color as 3 floats (RGB) = 12 bytes
		data.encode_float(offset, color.r)
		data.encode_float(offset + 4, color.g)
		data.encode_float(offset + 8, color.b)
		
		# Encode type as u8 = 1 byte
		data.encode_u8(offset + 12, type)
		
		offset += 13
	
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	player_id = data.decode_u8(1)
	
	var offset = 2
	for part_name in PART_NAMES:
		# Decode color from 3 floats
		var r = data.decode_float(offset)
		var g = data.decode_float(offset + 4)
		var b = data.decode_float(offset + 8)
		colors[part_name] = Color(r, g, b)
		
		# Decode type
		types[part_name] = data.decode_u8(offset + 12)
		
		offset += 13
