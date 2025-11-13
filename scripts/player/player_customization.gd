extends Node
class_name PlayerCustomization


class Part:
	var line_type: int
	var line_node: Node

	var color: Color
	var color_node: Node
	
	
	func _init(name: String,
			   player: CharacterBody2D,
			   default_line_type: int,	
			   default_color: Color) -> void:
		self.line_type = default_line_type
		self.color = default_color

		self.line_node = player.get_node_or_null("Sprite/" + name)
		self.color_node = player.get_node_or_null("Sprite/" + name + "_Color")


var player: CharacterBody2D
var active_player_customization: Dictionary = {}


func _ready() -> void:
	player = get_parent() as CharacterBody2D

	active_player_customization = {
		"Head": Part.new("Head", player, CustomizationConstants.Head_Type.CLASSIC, Color.DARK_GRAY),
		"Body": Part.new("Body", player, CustomizationConstants.Body_Type.CLASSIC, Color.DARK_GRAY),
		"Eyes": Part.new("Eyes", player, CustomizationConstants.Eyes_Type.CLASSIC, Color.DARK_GRAY),
		"Tail": Part.new("Tail", player, CustomizationConstants.Tail_Type.CLASSIC, Color.DARK_GRAY),
		"Wings": Part.new("Wings", player, CustomizationConstants.Wings_Type.CLASSIC, Color.DARK_GRAY),
		"Horns": Part.new("Horns", player, CustomizationConstants.Horns_Type.CLASSIC, Color.DARK_GRAY)
	}

	call_deferred("apply_all_customization")


func apply_all_customization() -> void:
	for part_name in active_player_customization:
		apply_customization(part_name, active_player_customization[part_name])


func apply_customization(part_name: String, part: Part) -> void:
	# Apply color modulation
	if part.color_node:
		part.color_node.self_modulate = part.color

	# Apply line type and texture
	if part.line_node:
		# Change visibility
		if part.line_type == 0:
			part.line_node.visible = false
			part.color_node.visible = false
		else:
			part.line_node.visible = true
			part.color_node.visible = true

			# change texture
			part.line_node.texture = CustomizationConstants.textures[part_name][part.line_type]["line"]
			part.color_node.texture = CustomizationConstants.textures[part_name][part.line_type]["color"]
			



func apply_color(color_key: String) -> void:
	if not player or color_key not in SPRITE_PATHS:
		return
	
	var color: Color = customization_data[color_key]
	var paths: Array = SPRITE_PATHS[color_key]
	
	for path in paths:
		var node = player.get_node_or_null(path)
		if node and node.visible:
			node.self_modulate = color


func apply_feature(feature_name: String) -> void:
	if not player or feature_name not in FEATURE_NODES:
		return
	
	var type_key_map := {
		"wings": "wing_type",
		"horns": "horn_type",
		"markings": "markings_type"
	}
	
	var type_key: String = type_key_map.get(feature_name, feature_name + "_type")
	var type: int = customization_data[type_key]
	var nodes: Dictionary = FEATURE_NODES[feature_name]
	
	var base_node = player.get_node_or_null(nodes["base"])
	if not base_node:
		return
	
	if type == 0:
		base_node.visible = false
		if nodes["color"]:
			var color_node = player.get_node_or_null(nodes["color"])
			if color_node:
				color_node.visible = false
		return
	
	base_node.visible = true
	
	var texture_dict: Dictionary
	match feature_name:
		"wings":
			texture_dict = wing_textures
		"horns":
			texture_dict = horn_textures
		"markings":
			texture_dict = markings_textures
	
	if type in texture_dict:
		if texture_dict[type] is Dictionary:
			base_node.texture = texture_dict[type]["base"]
			if nodes["color"]:
				var color_node = player.get_node_or_null(nodes["color"])
				if color_node:
					color_node.visible = true
					color_node.texture = texture_dict[type]["color"]
		else:
			base_node.texture = texture_dict[type]


func get_color(body_part: String) -> Color: return customization_data[body_part] 
func get_feature_type(body_part: String) -> int: return customization_data[body_part] 


func set_customization(key: String, value) -> void:
	if key not in customization_data:
		return
	
	customization_data[key] = value
	
	if key.ends_with("_color"):
		apply_color(key)
	elif key.ends_with("_type"):
		var feature_name = key.replace("_type", "") + "s" if key != "markings_type" else "markings"
		apply_feature(feature_name)
		apply_color(key.replace("_type", "_color"))


func apply_from_dict(data: Dictionary) -> void:
	for key in data:
		if key in customization_data:
			customization_data[key] = data[key]
	apply_all_customization()


func read_from_player() -> void:
	if not player:
		return
	
	for color_key in ["body_color", "eye_color", "wing_color", "horn_color", "markings_color"]:
		if color_key in SPRITE_PATHS:
			var path = SPRITE_PATHS[color_key][0]
			var node = player.get_node_or_null(path)
			if node:
				customization_data[color_key] = node.self_modulate
	
	_read_feature_type("wings", wing_textures)
	_read_feature_type("horns", horn_textures)
	_read_feature_type("markings", markings_textures)


func _read_feature_type(feature_name: String, texture_dict: Dictionary) -> void:
	var nodes = FEATURE_NODES[feature_name]
	var base_node = player.get_node_or_null(nodes["base"])
	
	if not base_node:
		return
	
	var type_key_map := {
		"wings": "wing_type",
		"horns": "horn_type",
		"markings": "markings_type"
	}
	
	var type_key: String = type_key_map.get(feature_name, feature_name + "_type")
	
	if not base_node.visible:
		customization_data[type_key] = 0
		return
	
	var current_texture = base_node.texture
	for type in texture_dict:
		var texture_to_compare
		if texture_dict[type] is Dictionary:
			texture_to_compare = texture_dict[type]["base"]
		else:
			texture_to_compare = texture_dict[type]
		
		if current_texture == texture_to_compare:
			customization_data[type_key] = type
			return
	
	customization_data[type_key] = texture_dict.keys()[0] if not texture_dict.is_empty() else 0
