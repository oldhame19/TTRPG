#held_items_data.gd
class_name HeldItemsData extends Resource

@export var slots: Array[SlotData] = []

func add_hold_item(new_item: SlotData) -> void:
	for slot in slots:
		if slot.item_data == new_item.item_data:
			var max_stack = slot.item_data.stack_size
			var space_left = max_stack - slot.quantity

			if space_left > 0:
				var amount_to_add = min(space_left, new_item.quantity)
				slot.quantity += amount_to_add
				new_item.quantity -= amount_to_add

				# If there’s still leftover quantity and space in held_items, add a new slot
				if new_item.quantity > 0 and slots.size() < 5:
					var extra_slot := SlotData.new()
					extra_slot.item_data = new_item.item_data
					extra_slot.quantity = new_item.quantity
					slots.append(extra_slot)
				return

	# If no stack found or couldn't stack, and there's space, add as new slot
	if slots.size() < 5 and new_item.quantity > 0:
		var slot := SlotData.new()
		slot.item_data = new_item.item_data
		slot.quantity = new_item.quantity
		slots.append(slot)

func is_full() -> bool:
	return slots.size() >= 5

func remove_item(item: SlotData) -> void:
	if item in slots:
		item.quantity = max(0, item.quantity - 1)
		if item.quantity == 0:
			slots.erase(item)
			
