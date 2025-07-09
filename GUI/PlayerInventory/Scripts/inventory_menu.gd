extends CanvasLayer

@export var unit: Unit
@onready var item_list_container = $Panel/VBoxContainer/ScrollContainer/ItemListContainer

const CATEGORY_ALL: int = -1  # For showing everything

@onready var tab_buttons := {
	ItemData.Category.Provisions: $Panel/VBoxContainer/CategoryTabs/ProvisionsButton,
	ItemData.Category.Misc: $Panel/VBoxContainer/CategoryTabs/MiscButton,
	ItemData.Category.Key: $Panel/VBoxContainer/CategoryTabs/KeyItemsButton,
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
	# Clear previous item UI
	for child in item_list_container.get_children():
		child.queue_free()

	# Create an icon + button row per item
	for slot in items:
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_END  # align right

		var icon := TextureRect.new()
		icon.texture = slot.item_data.texture
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)

		var button := Button.new()
		button.text = "%s x%d" % [slot.item_data.name, slot.quantity]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): _on_item_selected(slot))
		hbox.add_child(button)

		item_list_container.add_child(hbox)


func _on_item_selected(slot: SlotData) -> void:
	print("Selected:", slot.item_data.name)
	# You could open a Use/Equip/Discard menu here
