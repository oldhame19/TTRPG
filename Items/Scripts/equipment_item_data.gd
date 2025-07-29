#equipment_item_data.gd
class_name EquipmentItemData
extends ItemData

enum EquipmentType {NONE, SHIELD, HEADGEAR, JEWELRY}

@export var equipment_type: EquipmentType = EquipmentType.NONE
@export var defense_bonus: int = 0
