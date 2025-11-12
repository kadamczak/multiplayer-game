extends Node
class_name PlayerCustomization

# Customization properties
var body_color: Color = Color.WHITE
var eye_color: Color = Color.WHITE
var wing_color: Color = Color.WHITE
var horn_color: Color = Color.WHITE
var markings_color: Color = Color.WHITE
var wing_type: int = 1  # Default to Wings 1 (0 = none, 1 = wings1, 2 = wings2)
var horn_type: int = 1  # Default to Horns 1 (0 = none, 1 = horns1)
var markings_type: int = 0  # Default to No Markings (0 = none, 1 = markings1, 2 = markings2)

# Preload textures
var wings_textures = {
	1: {
		"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1.png"),
		"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1_Color.png")
	},
	2: {
		"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2.png"),
		"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2_Color.png")
	}
}

var horns_textures = {
	1: {
		"base": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Horns_1.png"),
		"color": preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Horns_1_Color.png")
	}
}

var markings_textures = {
	1: preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Markings_1.png"),
	2: preload("res://assets/spritesheets/dragon_spritesheets/Dragon_Markings_2.png")
}

# Reference to the player node
var player: CharacterBody2D

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	# Apply initial customization after a frame to ensure sprite nodes are ready
	call_deferred("apply_all_customization")

# Apply all customization to the player sprite
func apply_all_customization() -> void:
	apply_body_color(body_color)
	apply_eye_color(eye_color)
	apply_wings(wing_type)
	apply_wings_color(wing_color)
	apply_horns(horn_type)
	apply_horns_color(horn_color)
	apply_markings(markings_type)
	apply_markings_color(markings_color)

# Individual application methods
func apply_body_color(color: Color) -> void:
	body_color = color
	if not player: return
	
	if player.has_node("Sprite/Tail_Color"):
		player.get_node("Sprite/Tail_Color").self_modulate = color
	if player.has_node("Sprite/Body_Color"):
		player.get_node("Sprite/Body_Color").self_modulate = color
	if player.has_node("Sprite/Head_Color"):
		player.get_node("Sprite/Head_Color").self_modulate = color

func apply_eye_color(color: Color) -> void:
	eye_color = color
	if not player: return
	
	if player.has_node("Sprite/Eyes_Color"):
		player.get_node("Sprite/Eyes_Color").self_modulate = color

func apply_wings(type: int) -> void:
	wing_type = type
	if not player: return
	
	var wings_node = player.get_node_or_null("Sprite/Wings")
	var wings_color_node = player.get_node_or_null("Sprite/Wings_Color")
	
	if not wings_node or not wings_color_node:
		return
	
	if type == 0:
		wings_node.visible = false
		wings_color_node.visible = false
	else:
		wings_node.visible = true
		wings_color_node.visible = true
		
		if type in wings_textures:
			wings_node.texture = wings_textures[type]["base"]
			wings_color_node.texture = wings_textures[type]["color"]

func apply_wings_color(color: Color) -> void:
	wing_color = color
	if not player: return
	
	var wings_color_node = player.get_node_or_null("Sprite/Wings_Color")
	if wings_color_node and wings_color_node.visible:
		wings_color_node.self_modulate = color

func apply_horns(type: int) -> void:
	horn_type = type
	if not player: return
	
	var horns_node = player.get_node_or_null("Sprite/Horns")
	var horns_color_node = player.get_node_or_null("Sprite/Horns_Color")
	
	if not horns_node or not horns_color_node:
		return
	
	if type == 0:
		horns_node.visible = false
		horns_color_node.visible = false
	else:
		horns_node.visible = true
		horns_color_node.visible = true
		
		if type in horns_textures:
			horns_node.texture = horns_textures[type]["base"]
			horns_color_node.texture = horns_textures[type]["color"]

func apply_horns_color(color: Color) -> void:
	horn_color = color
	if not player: return
	
	var horns_color_node = player.get_node_or_null("Sprite/Horns_Color")
	if horns_color_node and horns_color_node.visible:
		horns_color_node.self_modulate = color

func apply_markings(type: int) -> void:
	markings_type = type
	if not player: return
	
	var markings_node = player.get_node_or_null("Sprite/Markings")
	
	if not markings_node:
		return
	
	if type == 0:
		markings_node.visible = false
	else:
		markings_node.visible = true
		
		if type in markings_textures:
			markings_node.texture = markings_textures[type]

func apply_markings_color(color: Color) -> void:
	markings_color = color
	if not player: return
	
	var markings_node = player.get_node_or_null("Sprite/Markings")
	if markings_node and markings_node.visible:
		markings_node.self_modulate = color

# Read current customization from player sprite
func read_from_player() -> void:
	if not player: return
	
	# Read body color
	if player.has_node("Sprite/Tail_Color"):
		body_color = player.get_node("Sprite/Tail_Color").self_modulate
	
	# Read eye color
	if player.has_node("Sprite/Eyes_Color"):
		eye_color = player.get_node("Sprite/Eyes_Color").self_modulate
	
	# Read wings
	if player.has_node("Sprite/Wings"):
		var wings_node = player.get_node("Sprite/Wings")
		if not wings_node.visible:
			wing_type = 0
		else:
			var wings_texture = wings_node.texture
			if wings_texture == wings_textures[1]["base"]:
				wing_type = 1
			elif wings_texture == wings_textures[2]["base"]:
				wing_type = 2
			
			if player.has_node("Sprite/Wings_Color"):
				wing_color = player.get_node("Sprite/Wings_Color").self_modulate
	
	# Read horns
	if player.has_node("Sprite/Horns"):
		var horns_node = player.get_node("Sprite/Horns")
		if not horns_node.visible:
			horn_type = 0
		else:
			horn_type = 1
			
			if player.has_node("Sprite/Horns_Color"):
				horn_color = player.get_node("Sprite/Horns_Color").self_modulate
	
	# Read markings
	if player.has_node("Sprite/Markings"):
		var markings_node = player.get_node("Sprite/Markings")
		if not markings_node.visible:
			markings_type = 0
		else:
			var markings_texture = markings_node.texture
			if markings_texture == markings_textures[1]:
				markings_type = 1
			elif markings_texture == markings_textures[2]:
				markings_type = 2
			
			markings_color = markings_node.self_modulate

