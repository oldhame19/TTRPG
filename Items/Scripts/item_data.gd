#item_data.gd
class_name ItemData 
extends Resource

enum Category {MELEE, RANGED, PROVISIONS, MISC, EQUIPMENT}

#global variables
@export var name:  String = ""
@export_multiline var description : String = ""
@export var category: Category = Category.MISC
@export var stack_size: int = 1
@export var max_durability: int = 0
@export var durability: int = 0 #used for both weapon durability and consumables
@export var weight: int = 0
@export var texture: Texture2D
@export var equipped: bool = false

func use(user: Unit) -> bool:
	durability -= 1
	return durability <= 0  # Return true if item should be destroyed

func clone() -> ItemData:
	var new_item = ItemData.new()
	# Copy all necessary fields, including durability
	new_item.name = name
	new_item.texture = texture
	new_item.max_durability = max_durability
	new_item.durability = durability
	# copy other fields as needed
	return new_item
