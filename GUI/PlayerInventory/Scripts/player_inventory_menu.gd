extends CanvasLayer

@export var unit: Unit
@onready var item_list_container = $Panel/VBoxContainer/ScrollContainer/ItemListContainer

const CATEGORY_ALL: int = -1  # For showing everything

@onready var tab_buttons := {
	ItemData.Category.PROVISIONS: $Panel/VBoxContainer/CategoryTabs/ProvisionsButton,
	ItemData.Category.MISC: $Panel/VBoxContainer/CategoryTabs/MiscButton,
	ItemData.Category.EQUIPMENT: $Panel/VBoxContainer/CategoryTabs/EquipmentButton,
	ItemData.Category.RANGED: $Panel/VBoxContainer/CategoryTabs/RangedButton,
	ItemData.Category.MELEE: $Panel/VBoxContainer/CategoryTabs/MeleeButton,
	CATEGORY_ALL: $Panel/VBoxContainer/CategoryTabs/AllButton
}

func _ready():
	if not unit:
		push_warning("No unit assigned to inventory menu.")
		queue_free()
		return

	# Hook up tab button presses to filter inventory
	for category in tab_buttons:
		tab_buttons[category].pressed.connect(func():
			populate_items(category)
		)

	populate_items(CATEGORY_ALL)  # Show all items initially

func _on_item_selected(slot: SlotData, button: Button) -> void:
	# Close existing selected item menus
	for child in get_tree().get_root().get_children():
		if child.get_script() and child.get_script().resource_path == "res://GUI/ItemMenus/selected_item_menu.gd":
			child.queue_free()

	var popup = preload("res://GUI/ItemMenus/selected_item_menu.tscn").instantiate()
	popup.slot = slot
	popup.unit = unit
	popup.source = "inventory"
	get_tree().get_root().add_child(popup)

	# Position popup to the right of the pressed button with a small offset
	var button_global_pos = button.get_global_position()
	var button_size = button.get_size()

	# Offset right by button width + 10 pixels, and align vertically with button
	var popup_offset = Vector2(button_size.x + 175, 170)
	popup.set_global_position(button_global_pos + popup_offset)


func populate_items(category: int) -> void:
	var items: Array[SlotData]
	

	if category == CATEGORY_ALL:
		items = unit.inventory.slots.duplicate()
	else:
		items = unit.inventory.slots.filter(func(slot: SlotData) -> bool:
			return slot.item_data.category == category
		)

	display_items(items)

func display_items(items: Array[SlotData]) -> void:
	# Clear previous list
	for child in item_list_container.get_children():
		child.queue_free()

	for slot in items:
		# Create the button
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(400, 40)
		button.focus_mode = Control.FOCUS_ALL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(b=button, s=slot): _on_item_selected(s, b))
		

		# HBox inside the button
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.custom_minimum_size = Vector2(400, 40)
		hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		hbox.add_theme_constant_override("separation", 0)

		# Left buffer
		var left_buffer := Control.new()
		left_buffer.custom_minimum_size = Vector2(16, 0)
		hbox.add_child(left_buffer)

		# Icon
		var icon := TextureRect.new()
		icon.texture = slot.item_data.texture
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)

		# Spacer between icon and name
		var icon_name_spacer := Control.new()
		icon_name_spacer.custom_minimum_size = Vector2(8, 0)
		hbox.add_child(icon_name_spacer)

		# Item name
		var name_label := Label.new()
		name_label.text = slot.item_data.name
		# Change from EXPAND_FILL to SHRINK_CENTER with fixed width so qty_label isn’t pushed far right
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		name_label.custom_minimum_size = Vector2(275, 0)  # Adjust width as needed
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hbox.add_child(name_label)

		# Quantity label
		var qty_label := Label.new()
		qty_label.text = "x%d" % slot.quantity
		qty_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		qty_label.custom_minimum_size = Vector2(50, 32)
		hbox.add_child(qty_label)

		# *** Removed right buffer spacer here ***

		# Assemble and add to container
		button.add_child(hbox)
		item_list_container.add_child(button)
		

#func _on_item_selected(slot: SlotData) -> void:
	## Close existing selected item menus
	#for child in get_tree().get_root().get_children():
		#if child.get_script() and child.get_script().resource_path == "res://GUI/ItemMenus/selected_item_menu.gd":
			#child.queue_free()
#
	#var popup = preload("res://GUI/ItemMenus/selected_item_menu.tscn").instantiate()
	#popup.slot = slot
	#popup.unit = unit
	#popup.source = "inventory"
	#get_tree().get_root().add_child(popup)
