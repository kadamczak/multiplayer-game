class_name CustomizationConstants


enum Head_Type {
	CLASSIC = 1
}

enum Body_Type {
	CLASSIC = 1
}

enum Eyes_Type {
	CLASSIC = 1
}

enum Tail_Type {
	CLASSIC = 1
}

enum Wings_Type {
	NO_WINGS = 0,
	CLASSIC = 1,
	FEATHERED = 2
}

enum Horns_Type {
	NO_HORNS = 0,
	CLASSIC = 1
}


const textures = {
	"Head": 
		{
			CustomizationConstants.Head_Type.CLASSIC: {
				"line": preload(CustomizationConstants.head_1_texture),
				"color": preload(CustomizationConstants.head_1_color_texture)
			}
		},
	"Body": 
		{
			CustomizationConstants.Body_Type.CLASSIC: {
				"line": preload(CustomizationConstants.body_1_texture),
				"color": preload(CustomizationConstants.body_1_color_texture)
			}
		},
	"Eyes": 
		{
			CustomizationConstants.Eyes_Type.CLASSIC: {
				"line": preload(CustomizationConstants.eyes_1_texture),
				"color": preload(CustomizationConstants.eyes_1_color_texture)
			}
		},
	"Tail": 
		{
			CustomizationConstants.Tail_Type.CLASSIC: {
				"line": preload(CustomizationConstants.tail_1_texture),
				"color": preload(CustomizationConstants.tail_1_color_texture)
			}
		},
	"Wings": 
		{
			CustomizationConstants.Wings_Type.CLASSIC: {
				"line": preload(CustomizationConstants.wings_1_texture),
				"color": preload(CustomizationConstants.wings_1_color_texture)
			},
			CustomizationConstants.Wings_Type.FEATHERED: {
				"line": preload(CustomizationConstants.wings_2_texture),
				"color": preload(CustomizationConstants.wings_2_color_texture)
			}
		},
	"Horns": 
		{
			CustomizationConstants.Horns_Type.CLASSIC: {
				"line": preload(CustomizationConstants.horns_1_texture),
				"color": preload(CustomizationConstants.horns_1_color_texture)
			}
		}
}


const head_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Head_1.png"
const head_1_color_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Head_1_Color.png"

const body_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Body_1.png"
const body_1_color_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Body_1_Color.png"

const eyes_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Eyes_1.png"
const eyes_1_color_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Eyes_1_Color.png"

const tail_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Tail_1.png"
const tail_1_color_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Tail_1_Color.png"

const wings_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1.png"
const wings_1_color_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1_Color.png"

const wings_2_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2.png"
const wings_2_color_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2_Color.png"

const horns_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Horns_1.png"
const horns_1_color_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Horns_1_Color.png"