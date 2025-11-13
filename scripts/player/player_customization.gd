extends Node
class_name PlayerCustomization

# Customization data structure
var customization_data := {
	"body_color": Color.DARK_GRAY,
	"eye_color": Color.DARK_GRAY,
	"wing_color": Color.DARK_GRAY,
	"horn_color": Color.DARK_GRAY,
	"markings_color": Color.DARK_GRAY,
	"wing_type": 1,
	"horn_type": 1,
	"markings_type": 0
}

# Sprite node paths for each customization type
const SPRITE_PATHS := {
	"body_color": ["Sprite/Tail_Color", "Sprite/Body_Color", "Sprite/Head_Color"],
	"eye_color": ["Sprite/Eyes_Color"],
	"wing_color": ["Sprite/Wings_Color"],
	"horn_color": ["Sprite/Horns_Color"],
	"markings_color": ["Sprite/Markings"]
}

const FEATURE_NODES := {
	"wings": {"base": "Sprite/Wings", "color": "Sprite/Wings_Color"},
	"horns": {"base": "Sprite/Horns", "color": "Sprite/Horns_Color"},
	"markings": {"base": "Sprite/Markings", "color": null}
}

# Texture resources
var wings_textures := {
	1: {
		"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1.png"),
		"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1_Color.png")
	},
	2: {
		"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2.png"),
		"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2_Color.png")
	}
}

var horns_textures := {
	1: {
		"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Horns_1.png"),
		"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Horns_1_Color.png")
	}
}

var markings_textures := {
	1: preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Markings_1.png"),
	2: preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Markings_2.png")
}

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent() as CharacterBody2D
	call_deferred("apply_all_customization")


# Apply all customization at once
func apply_all_customization() -> void:
	apply_color("body_color")
	apply_color("eye_color")
	apply_feature("wings")
	apply_color("wing_color")
	apply_feature("horns")
	apply_color("horn_color")
	apply_feature("markings")
	apply_color("markings_color")


# Generic color application
func apply_color(color_key: String) -> void:
	if not player or color_key not in SPRITE_PATHS:
		return
	
	var color: Color = customization_data[color_key]
	var paths: Array = SPRITE_PATHS[color_key]
	
	for path in paths:
		var node = player.get_node_or_null(path)
		if node and node.visible:
			node.self_modulate = color


# Generic feature application (wings, horns, markings)
func apply_feature(feature_name: String) -> void:
	if not player or feature_name not in FEATURE_NODES:
		return
	
	# Map feature names to their type keys (handle singular/plural)
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
	
	# Handle visibility
	if type == 0:
		base_node.visible = false
		if nodes["color"]:
			var color_node = player.get_node_or_null(nodes["color"])
			if color_node:
				color_node.visible = false
		return
	
	# Show and set texture
	base_node.visible = true
	
	# Get appropriate texture dictionary
	var texture_dict: Dictionary
	match feature_name:
		"wings":
			texture_dict = wings_textures
		"horns":
			texture_dict = horns_textures
		"markings":
			texture_dict = markings_textures
	
	if type in texture_dict:
		if texture_dict[type] is Dictionary:
			# Has base and color textures
			base_node.texture = texture_dict[type]["base"]
			if nodes["color"]:
				var color_node = player.get_node_or_null(nodes["color"])
				if color_node:
					color_node.visible = true
					color_node.texture = texture_dict[type]["color"]
		else:
			# Single texture (markings)
			base_node.texture = texture_dict[type]


# Setters for individual properties
func set_body_color(color: Color) -> void:
	customization_data["body_color"] = color
	apply_color("body_color")

func set_eye_color(color: Color) -> void:
	customization_data["eye_color"] = color
	apply_color("eye_color")

func set_wing_color(color: Color) -> void:
	customization_data["wing_color"] = color
	apply_color("wing_color")

func set_horn_color(color: Color) -> void:
	customization_data["horn_color"] = color
	apply_color("horn_color")

func set_markings_color(color: Color) -> void:
	customization_data["markings_color"] = color
	apply_color("markings_color")

func set_wing_type(type: int) -> void:
	customization_data["wing_type"] = type
	apply_feature("wings")
	apply_color("wing_color")

func set_horn_type(type: int) -> void:
	customization_data["horn_type"] = type
	apply_feature("horns")
	apply_color("horn_color")

func set_markings_type(type: int) -> void:
	customization_data["markings_type"] = type
	apply_feature("markings")
	apply_color("markings_color")


# Getters
func get_body_color() -> Color:
	return customization_data["body_color"]

func get_eye_color() -> Color:
	return customization_data["eye_color"]

func get_wing_color() -> Color:
	return customization_data["wing_color"]

func get_horn_color() -> Color:
	return customization_data["horn_color"]

func get_markings_color() -> Color:
	return customization_data["markings_color"]

func get_wing_type() -> int:
	return customization_data["wing_type"]

func get_horn_type() -> int:
	return customization_data["horn_type"]

func get_markings_type() -> int:
	return customization_data["markings_type"]


# Apply all customization from a data dictionary
func apply_from_dict(data: Dictionary) -> void:
	for key in data:
		if key in customization_data:
			customization_data[key] = data[key]
	apply_all_customization()


# Read current customization from player sprite
func read_from_player() -> void:
	if not player:
		return
	
	# Read colors
	for color_key in ["body_color", "eye_color", "wing_color", "horn_color", "markings_color"]:
		if color_key in SPRITE_PATHS:
			var path = SPRITE_PATHS[color_key][0]
			var node = player.get_node_or_null(path)
			if node:
				customization_data[color_key] = node.self_modulate
	
	# Read feature types
	_read_feature_type("wings", wings_textures)
	_read_feature_type("horns", horns_textures)
	_read_feature_type("markings", markings_textures)


func _read_feature_type(feature_name: String, texture_dict: Dictionary) -> void:
	var nodes = FEATURE_NODES[feature_name]
	var base_node = player.get_node_or_null(nodes["base"])
	
	if not base_node:
		return
	
	# Map feature names to their type keys (handle singular/plural)
	var type_key_map := {
		"wings": "wing_type",
		"horns": "horn_type",
		"markings": "markings_type"
	}
	
	var type_key: String = type_key_map.get(feature_name, feature_name + "_type")
	
	if not base_node.visible:
		customization_data[type_key] = 0
		return
	
	# Check which texture is active
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
	
	# Default to first type if no match
	customization_data[type_key] = texture_dict.keys()[0] if not texture_dict.is_empty() else 0
