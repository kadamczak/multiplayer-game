class_name Customization

class Part:
	var line_type: int
	var line_node_path: String

	var color: Color
	var color_node_path: String
	
	var textures: Dictionary
	
	func _init(name: String,
			   default_line_type: int,	
			   default_color: Color,
			   textures: Dictionary) -> void:
		self.line_type = default_line_type
		self.color = default_color

		self.line_node_path = "Sprite/" + name
		self.color_node_path = "Sprite/" + name + "_Color"

		self.textures = textures

