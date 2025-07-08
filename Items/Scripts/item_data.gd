class_name ItemData extends Resource

enum Category {Melee, Ranged, Armor, Provisions, Misc, Key}
enum WeaponType { None, Sword, Spear, Club, Axe, Bow, Sling, Shield, Special}

@export var name:  String = ""
@export_multiline var description : String = ""
@export var category: Category = Category.Misc
@export var weapon_type: WeaponType = WeaponType.None
@export var stack_size: int = 1
@export var durability: int = 1 #usef for both weapon durability and consumables
@export var texture: Texture2D
