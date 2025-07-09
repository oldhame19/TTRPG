class_name ItemData extends Resource

enum Category {Melee, Ranged, Provisions, Misc, Key}
enum WeaponType { None, Sword, Spear, Club, Axe, Bow, Sling, Shield, Special}

#global variable
@export var name:  String = ""
@export_multiline var description : String = ""
@export var category: Category = Category.Misc
@export var stack_size: int = 1
@export var durability: int = 0 #usef for both weapon durability and consumables
@export var weight: int = 0
@export var texture: Texture2D
#weapon/shield variables
@export var weapon_type: WeaponType = WeaponType.None
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
#provisions variables
@export var heal_amount: int = 0
@export var consumable: bool = false

func is_weapon() -> bool:
	return category in [Category.Melee, Category.Ranged]

func is_consumable() -> bool:
	return category == Category.Provisions and heal_amount > 0 and consumable
