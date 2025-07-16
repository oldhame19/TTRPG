# slot_data.gd
class_name SlotData
extends Resource

@export var item_data : ItemData
@export var quantity: int = 0

func clone() -> SlotData:
	var new_slot = SlotData.new()
	new_slot.item_data = item_data
	new_slot.quantity = quantity
	return new_slot
