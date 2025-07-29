#weapon_item_data.gd
class_name WeaponItemData
extends ItemData

enum WeaponType { NONE, SWORD, SPEAR, CLUB, AXE, BOW, SLING, SPECIAL}
enum Effectiveness {NONE, GIANT, CAVALRY}

@export var weapon_type: WeaponType = WeaponType.NONE
@export var power: int = 0
@export var atk_range: int = 0
@export var hit_chance: int = 0
@export var crit_chance: int = 0
@export var effective_against: Effectiveness = Effectiveness.NONE
@export var equipped: bool = false
