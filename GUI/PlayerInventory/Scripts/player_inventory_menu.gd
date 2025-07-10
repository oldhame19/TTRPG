extends CanvasLayer

@export var unit: Unit
@onready var item_list_container = $Panel/VBoxContainer/ScrollContainer/ItemListContainer

const CATEGORY_ALL: int = -1  # For showing everything

@onready var tab_buttons := {
	ItemData.Category.Provisions: $Panel/VBoxContainer/CategoryTabs/ProvisionsButton,
	ItemData.Category.Misc: $Panel/VBoxContainer/CategoryTabs/MiscButton,
	ItemData.Category.Equipment: $Panel/VBoxContainer/CategoryTabs/EquipmentButton,
	ItemData.Category.Ranged: $Panel/VBoxContainer/CategoryTabs/RangedButton,
	ItemData.Category.Melee: $Panel/VBoxContainer/CategoryTabs/MeleeButton,
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


func _on_close_button_pressed() -> void:
	queue_free()

func _on_item_selected(slot: SlotData) -> void:
	print("Selected:", slot.item_data.name)
	# You could open a Use/Equip/Discard menu here

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
		button.pressed.connect(func(): _on_item_selected(slot))

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
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hbox.add_child(name_label)

		# Quantity label
		var qty_label := Label.new()
		qty_label.text = "x%d" % slot.quantity
		qty_label.size_flags_horizontal = Control.SIZE_EXPAND
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		qty_label.custom_minimum_size = Vector2(50, 32)
		hbox.add_child(qty_label)

		# Right buffer to give padding from edge
		var right_buffer := Control.new()
		right_buffer.custom_minimum_size = Vector2(16, 0)
		hbox.add_child(right_buffer)

		# Assemble and add to container
		button.add_child(hbox)
		item_list_container.add_child(button)
