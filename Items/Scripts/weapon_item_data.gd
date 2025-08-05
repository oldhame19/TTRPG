#weapon_item_data.gd
class_name WeaponItemData
extends ItemData

enum WeaponType { NONE, SWORD, SPEAR, CLUB, AXE, BOW, SLING, SPECIAL}
enum Effectiveness {NONE, GIANT, CAVALRY}

@export var weapon_type: WeaponType = WeaponType.NONE
@export var power: int = 0
@export var atk_range: int = 0
@export var hit_chance: int = 0
@export var distance_hit_penalty: int = 0
@export var crit_chance: int = 0
@export var effective_against: Effectiveness = Effectiveness.NONE

func use(user: Unit) -> bool:
	if weapon_type == WeaponType.SLING:
		for slot in user.held_items.slots:
			if slot.item_data.name == "Stone" and slot.quantity > 0:
				slot.quantity -= 1
				if slot.quantity == 0:
					user.held_items.slots.erase(slot)
				break
	else:
		print("⚠ Cannot use sling — no stones!")
		return false  # Cancel use, do not decrement durability
	return super(user)
