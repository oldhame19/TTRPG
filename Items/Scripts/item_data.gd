#item_data.gd
class_name ItemData extends Resource

enum Category {MELEE, RANGED, PROVISIONS, MISC, EQUIPMENT}
enum WeaponType { NONE, SWORD, SPEAR, CLUB, AXE, BOW, SLING, SPECIAL}
enum EquipmentType {NONE, SHIELD, HEADGEAR, JEWELRY}
enum Effectiveness {NONE, GIANT, CAVALRY}
#global variables
@export var name:  String = ""
@export_multiline var description : String = ""
@export var category: Category = Category.MISC
@export var stack_size: int = 1
@export var max_durability: int = 0
@export var durability: int = 0 #used for both weapon durability and consumables
@export var weight: int = 0
@export var texture: Texture2D
#weapon variables
@export var weapon_type: WeaponType = WeaponType.NONE
@export var power: int = 0
@export var atk_range: int = 0
@export var hit_chance: int = 0
@export var crit_chance: int = 0
@export var effective_against: Effectiveness = Effectiveness.NONE
#equipment variables
@export var defense_bonus: int = 0
@export var equipped: bool = false
#provisions variables
@export var heal_amount: int = 0
@export var consumable: bool = false

func is_weapon() -> bool:
	return category in [Category.MELEE, Category.RANGED]

func is_consumable() -> bool:
	return category == Category.PROVISIONS and heal_amount > 0 and consumable
