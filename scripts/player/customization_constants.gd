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

enum Head_Item_Type {
	MAGE_HAT = 1,
	HEADPHONES = 2,
	HELMET = 5,
	CHEESE = 6
}

enum Body_Item_Type {
	LEG_ARMOR = 4,
	NECK_ARMOR = 10
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
	"Head_Item": 
		{
			CustomizationConstants.Head_Item_Type.MAGE_HAT: preload(CustomizationConstants.item_1_texture),
			CustomizationConstants.Head_Item_Type.HEADPHONES: preload(CustomizationConstants.item_2_texture),
			CustomizationConstants.Head_Item_Type.HELMET: preload(CustomizationConstants.item_5_texture),
			CustomizationConstants.Head_Item_Type.CHEESE: preload(CustomizationConstants.item_6_texture),
		},
	"Body_Item": 
		{
			CustomizationConstants.Body_Item_Type.LEG_ARMOR: preload(CustomizationConstants.item_4_texture),
			CustomizationConstants.Body_Item_Type.NECK_ARMOR: preload(CustomizationConstants.item_10_texture),
		}
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

const item_1_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Item_1.png"
const item_2_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Item_2.png"
const item_4_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Item_4.png"
const item_5_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Item_5.png"
const item_6_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Item_6.png"
const item_10_texture: String = "res://assets/spritesheets/dragon_spritesheets/Dragon_Item_10.png"
