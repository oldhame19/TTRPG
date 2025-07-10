extends CanvasLayer

@export var unit: Unit
@onready var item_list_container = $Panel/VBoxContainer/ScrollContainer/ItemListContainer

func _ready():
	if not unit:
		push_warning("No unit provided for HeldItemsMenu.")
		queue_free()
		return

	$Panel/VBoxContainer/Label.text = "%s's Items" % unit.name
	populate_items()

func populate_items():
	# Clear existing UI children properly
	for child in item_list_container.get_children():
		child.queue_free()

	for slot in unit.held_items.slots:
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(300, 40)

		# Add a left margin spacer for buffer before the icon
		var left_spacer = Control.new()
		left_spacer.custom_minimum_size = Vector2(8, 0)  # 8 pixels padding on left
		hbox.add_child(left_spacer)

		# Item icon
		var icon = TextureRect.new()
		icon.texture = slot.item_data.texture
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)

		# Small spacer between icon and name
		var icon_name_spacer = Control.new()
		icon_name_spacer.custom_minimum_size = Vector2(6, 0)
		hbox.add_child(icon_name_spacer)

		# Item name
		var name_label = Label.new()
		name_label.text = slot.item_data.name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		# Quantity label, right-aligned
		var qty_label = Label.new()
		qty_label.text = "x%d" % slot.quantity
		qty_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(qty_label)

		# Add the full row to the container
		item_list_container.add_child(hbox)


func _on_close_button_pressed() -> void:
	queue_free()
