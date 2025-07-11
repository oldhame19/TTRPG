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
		# Create the button
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(340, 40)
		button.focus_mode = Control.FOCUS_ALL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(b=button, s=slot): _on_item_selected(s, b))

		# HBox inside the button
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.custom_minimum_size = Vector2(340, 40)
		hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		hbox.add_theme_constant_override("separation", 0)

		# Left buffer
		var left_spacer := Control.new()
		left_spacer.custom_minimum_size = Vector2(10, 0)
		hbox.add_child(left_spacer)

		# Icon
		var icon := TextureRect.new()
		icon.texture = slot.item_data.texture
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)

		# Spacer between icon and name
		var icon_name_spacer := Control.new()
		icon_name_spacer.custom_minimum_size = Vector2(6, 0)
		hbox.add_child(icon_name_spacer)

		# Name label
		var name_label := Label.new()
		name_label.text = slot.item_data.name
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		name_label.custom_minimum_size = Vector2(220, 0)
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

		# Assemble and add to button, then to list
		button.add_child(hbox)
		item_list_container.add_child(button)


func _on_item_selected(slot: SlotData, button: Button) -> void:
	# Close any existing selected item menus
	for child in get_tree().get_root().get_children():
		if child.get_script() and child.get_script().resource_path == "res://GUI/ItemMenus/selected_item_menu.gd":
			child.queue_free()

	# Now create and show a new one
	var popup = preload("res://GUI/ItemMenus/selected_item_menu.tscn").instantiate()
	popup.slot = slot
	popup.unit = unit
	popup.source = "held_items"
	get_tree().get_root().add_child(popup)
	#popup.global_position = get_viewport().get_mouse_position()
		# Position popup to the right of the pressed button with a small offset
	var button_global_pos = button.get_global_position()
	var button_size = button.get_size()

	# Offset right by button width + 10 pixels, and align vertically with button
	var popup_offset = Vector2(button_size.x + -230, 170)
	popup.set_global_position(button_global_pos + popup_offset)



func _on_close_button_pressed() -> void:
	# If the unit is a player, look for and close their inventory menu too
	if unit and unit.is_player:
		for child in get_tree().get_root().get_children():
			if child is CanvasLayer and child.get_script().resource_path == "res://GUI/PlayerInventory/Scripts/player_inventory_menu.gd":
				if child.unit == unit:
					child.queue_free()
					break

	# Look for and close the selected item menu
	for child in get_tree().get_root().get_children():
		if child.get_script() and child.get_script().resource_path == "res://GUI/ItemMenus/selected_item_menu.gd":
			child.queue_free()
			break

	# Close this held items menu
	queue_free()
