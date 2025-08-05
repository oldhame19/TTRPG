#provision_item_data.gd
class_name ProvisionItemData
extends ItemData

#provisions variables
@export var heal_amount: int = 0
@export var consumable: bool = true

func use(user: Unit) -> bool:
	user.hp = clamp(user.hp + heal_amount, 0, user.current_stats.max_hp)
	return super(user)
