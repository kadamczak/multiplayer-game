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

enum Markings_Type {
	NO_MARKINGS = 0,
	STRIPES = 1,
	DOTS = 2
}


const textures = {
	"Head": 
		{
			CustomizationConstants.Head_Type.CLASSIC: preload(CustomizationConstants.head_1_texture)
		},
	"Body": 
		{
			CustomizationConstants.Body_Type.CLASSIC: preload(CustomizationConstants.body_1_texture)
		},
	"Eyes": 
		{
			CustomizationConstants.Eyes_Type.CLASSIC: preload(CustomizationConstants.eyes_1_texture)
		},
	"Tail": 
		{
			CustomizationConstants.Tail_Type.CLASSIC: preload(CustomizationConstants.tail_1_texture)
		},
	"Wings": 
		{
			CustomizationConstants.Wings_Type.CLASSIC: preload(CustomizationConstants.wings_1_texture),
			CustomizationConstants.Wings_Type.FEATHERED: preload(CustomizationConstants.wings_2_texture)
		},
	"Horns": 
		{
			CustomizationConstants.Horns_Type.CLASSIC: preload(CustomizationConstants.horns_1_texture)
		},
	"Markings": 
		{
			CustomizationConstants.Markings_Type.STRIPES: preload(CustomizationConstants.markings_1_texture),
			CustomizationConstants.Markings_Type.DOTS: preload(CustomizationConstants.markings_2_texture)
		},	
}


const head_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Head_1.png"
const body_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Body_1.png"
const eyes_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Eyes_1.png"
const tail_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Tail_1.png"
const wings_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_1.png"
const wings_2_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Wings_2.png"
const horns_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Horns_1.png"
const markings_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Markings_1.png"
const markings_2_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Markings_2.png"
