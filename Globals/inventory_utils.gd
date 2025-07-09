class_name InventoryUtils



#static func use_item(slots: Array[SlotData], slot: SlotData, user_unit: Unit) -> bool:
	#if not slot in slots:
		#return false
#
	#var item := slot.item_data
	#if item.is_consumable():
		#user_unit.hp = min(user_unit.max_hp, user_unit.hp + item.heal_amount)
		#slot.quantity -= 1
		#if slot.quantity <= 0:
			#slots.erase(slot)
		#return true
#
	#return false
#static func use_item(slots: Array[SlotData], slot: SlotData, user_unit: Unit) -> bool:
	## core logic...
#
#static func remove_item(slots: Array[SlotData], slot: SlotData) -> void:
	## removes a slot safely...
#
#static func equip_item(slot: SlotData, to_unit: Unit) -> void:
	## transfers to unit.held_items...
