extends Node
class_name PlayerCustomization

var player: CharacterBody2D


var parts: Dictionary = {
	"Body": Customization.Part.new("Body", 1, Color.DARK_GRAY,
		{
			1: {
				"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Body_1.png"),
				"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Body_1_Color.png")
			}
		}
	),
	"Head": Customization.Part.new("Head", 1, Color.DARK_GRAY,
		{
			1: {
				"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Head_1.png"),
				"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Head_1_Color.png")
			}
		}
	),
	"Eyes": Customization.Part.new("Eyes", 1, Color.DARK_GRAY,
		{
			1: {
				"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Eyes_1.png"),
				"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Eyes_1_Color.png")
			}
		}
	),
	"Tail": Customization.Part.new("Tail", 1, Color.DARK_GRAY,
		{
			1: {
				"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Tail_1.png"),
				"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Tail_1_Color.png")
			}
		}
	),
	"Wings": Customization.Part.new("Wings", 1, Color.DARK_GRAY,
		{
			1: {
				"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1.png"),
				"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1_Color.png")
			},
			2: {
				"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2.png"),
				"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2_Color.png")
			}
		}
	),
	"Horns": Customization.Part.new("Horns", 1, Color.DARK_GRAY,
		{
			1: {
				"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Horns_1.png"),
				"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Horns_1_Color.png")
			}
		}
	)
}


func _ready() -> void:
	player = get_parent() as CharacterBody2D
	call_deferred("apply_all_customization")


func apply_all_customization() -> void:
	apply_color("body_color")
	apply_color("eye_color")
	apply_color("wing_color")
	apply_color("horn_color")
	apply_color("markings_color")
	apply_feature("wings")
	apply_feature("horns")
	apply_feature("markings")


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
