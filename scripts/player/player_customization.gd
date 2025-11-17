extends Node
class_name PlayerCustomization


class Part:
	var name: String

	var line_type: int
	var line_node: Node

	var color: Color
	var color_node: Node
	
	
	func _init(name: String,
			   player: CharacterBody2D,
			   line: int,	
			   color: Color) -> void:
		self.name = name
		self.line_type = line
		self.color = color

		self.line_node = player.get_node_or_null("Sprite/" + name)
		self.color_node = player.get_node_or_null("Sprite/" + name + "_Color")


var player: CharacterBody2D
var active_player_customization: Dictionary = {}


func _ready() -> void:
	player = get_parent() as CharacterBody2D
	_set_default_customization()
	call_deferred("apply_all_customization")


func _set_default_customization() -> void:
	active_player_customization = {
		"Head": Part.new("Head", player, CustomizationConstants.Head_Type.CLASSIC, Color.DARK_GRAY),
		"Body": Part.new("Body", player, CustomizationConstants.Body_Type.CLASSIC, Color.DARK_GRAY),
		"Eyes": Part.new("Eyes", player, CustomizationConstants.Eyes_Type.CLASSIC, Color.LIGHT_BLUE),
		"Tail": Part.new("Tail", player, CustomizationConstants.Tail_Type.CLASSIC, Color.DARK_GRAY),
		"Wings": Part.new("Wings", player, CustomizationConstants.Wings_Type.CLASSIC, Color.DARK_SLATE_GRAY),
		"Horns": Part.new("Horns", player, CustomizationConstants.Horns_Type.CLASSIC, Color.GRAY)
	}


func apply_all_customization() -> void:
	for part_name in active_player_customization:
		apply_customization(active_player_customization[part_name])


func apply_customization(part: Part) -> void:
	# Apply color modulation
	if part.color_node:
		part.color_node.self_modulate = part.color

	# Apply part visibility and used texture
	if part.line_node:
		if part.line_type == 0:
			_change_part_visibility(part, false)
			return
		
		_change_part_visibility(part, true)
		_change_part_texture(part)
			

func _change_part_visibility(part: Part, is_visible: bool) -> void:
	part.line_node.visible = is_visible
	part.color_node.visible = is_visible


func _change_part_texture(part: Part):
	part.line_node.texture = CustomizationConstants.textures[part.name][part.line_type]["line"]
	part.color_node.texture = CustomizationConstants.textures[part.name][part.line_type]["color"]


