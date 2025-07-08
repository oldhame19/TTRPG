class_name HeldItems extends Resource

@export var held_items: Array[SlotData] = []

func add_hold_item(new_item: SlotData) -> void:
	for slot in held_items:
		if slot.item_data == new_item.item_data:
			var max_stack = slot.item_data.stack_size
			var space_left = max_stack - slot.quantity

			if space_left > 0:
				var amount_to_add = min(space_left, new_item.quantity)
				slot.quantity += amount_to_add
				new_item.quantity -= amount_to_add

				# If there’s still leftover quantity and space in held_items, add a new slot
				if new_item.quantity > 0 and held_items.size() < 5:
					var extra_slot := SlotData.new()
					extra_slot.item_data = new_item.item_data
					extra_slot.quantity = new_item.quantity
					held_items.append(extra_slot)
				return

	# If no stack found or couldn't stack, and there's space, add as new slot
	if held_items.size() < 5 and new_item.quantity > 0:
		var slot := SlotData.new()
		slot.item_data = new_item.item_data
		slot.quantity = new_item.quantity
		held_items.append(slot)


func remove_item(item: SlotData) -> void:
	if item in held_items:
		item.quantity = max(0, item.quantity - 1)
		if item.quantity == 0:
			held_items.erase(item)
