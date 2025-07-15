extends CanvasLayer

@export var unit: Unit
@onready var item_list_container = $Panel/VBoxContainer/ScrollContainer/ItemListContainer
var game_board
func _ready():
	if not unit:
		push_warning("No unit provided for HeldItemsMenu.")
		queue_free()
		return

	$Panel/VBoxContainer/Label.text = "%s's Items" % unit.name
	populate_items()

#func populate_items():
	## Clear existing UI children
	#for child in item_list_container.get_children():
		#child.queue_free()
#
	#for slot in unit.held_items.slots:
		#var button := Button.new()
		#button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		#button.custom_minimum_size = Vector2(340, 40)
		#button.focus_mode = Control.FOCUS_ALL
		#button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		#button.pressed.connect(func(b=button, s=slot): _on_item_selected(s, b))
#
		#var hbox := HBoxContainer.new()
		#hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		#hbox.custom_minimum_size = Vector2(340, 40)
		#hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		#hbox.add_theme_constant_override("separation", 0)
#
		#var left_spacer := Control.new()
		#left_spacer.custom_minimum_size = Vector2(10, 0)
		#hbox.add_child(left_spacer)
#
		#var icon := TextureRect.new()
		#icon.texture = slot.item_data.texture
		#icon.custom_minimum_size = Vector2(32, 32)
		#icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		#hbox.add_child(icon)
#
		#var icon_name_spacer := Control.new()
		#icon_name_spacer.custom_minimum_size = Vector2(6, 0)
		#hbox.add_child(icon_name_spacer)
#
		#var name_label := Label.new()
		#name_label.text = slot.item_data.name
		#name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		#name_label.custom_minimum_size = Vector2(220, 0)
		#name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		#hbox.add_child(name_label)
#
		#var qty_label := Label.new()
		#qty_label.text = "x%d" % slot.quantity
		#qty_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		#qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		#qty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		#qty_label.custom_minimum_size = Vector2(50, 32)
		#hbox.add_child(qty_label)
#
		#button.add_child(hbox)
		#item_list_container.add_child(button)
func populate_items():
	for child in item_list_container.get_children():
		child.queue_free()

	for slot in unit.held_items.slots:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(340, 40)
		button.focus_mode = Control.FOCUS_ALL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(b=button, s=slot): _on_item_selected(s, b))

		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.custom_minimum_size = Vector2(340, 40)
		hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		hbox.add_theme_constant_override("separation", 0)

		var left_spacer := Control.new()
		left_spacer.custom_minimum_size = Vector2(10, 0)
		hbox.add_child(left_spacer)

		var icon := TextureRect.new()
		icon.texture = slot.item_data.texture
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)

		var icon_name_spacer := Control.new()
		icon_name_spacer.custom_minimum_size = Vector2(6, 0)
		hbox.add_child(icon_name_spacer)

		# Name + Durability box
		var name_durability_box := HBoxContainer.new()
		name_durability_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_durability_box.custom_minimum_size = Vector2(0, 32)
		name_durability_box.alignment = BoxContainer.ALIGNMENT_BEGIN
		name_durability_box.add_theme_constant_override("separation", 4)

		var name_label := Label.new()
		name_label.text = slot.item_data.name
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_durability_box.add_child(name_label)

		if slot.item_data.max_durability > 0:
			var durability_label := Label.new()
			durability_label.text = "[%02d/%02d]" % [slot.item_data.durability, slot.item_data.max_durability]
			durability_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			durability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			durability_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			name_durability_box.add_child(durability_label)

		hbox.add_child(name_durability_box)

		var qty_label := Label.new()
		qty_label.text = "x%d" % slot.quantity
		qty_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		qty_label.custom_minimum_size = Vector2(50, 32)
		hbox.add_child(qty_label)

		var right_spacer := Control.new()
		right_spacer.custom_minimum_size = Vector2(16, 0)
		hbox.add_child(right_spacer)

		button.add_child(hbox)
		item_list_container.add_child(button)

func _on_item_selected(slot: SlotData, button: Button) -> void:
	var popup = preload("res://GUI/ItemMenus/selected_item_menu.tscn").instantiate()
	popup.source_button = button
	popup.slot = slot
	popup.unit = unit
	popup.source = "held_items"
	popup.game_board = game_board
	add_child(popup)

	var button_pos = button.get_position()
	var offset = Vector2()

	if unit and unit.is_player:
		offset = Vector2(140, 75)
	else:
		var unit_cell = unit.grid.calculate_grid_coordinates(unit.position)
		var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
		var adjacent_to_player = false

		for dir in directions:
			var neighbor_cell = unit_cell + dir
			if game_board._units.has(neighbor_cell):
				var neighbor = game_board._units[neighbor_cell]
				if neighbor.is_player:
					adjacent_to_player = true
					break

		if adjacent_to_player:
			offset = Vector2(140, 75)  # Use player-style offset
		else:
			offset = Vector2(344, 75)  # Default for non-player units

	popup.set_position(button_pos + offset)


func _on_close_button_pressed() -> void:
	if unit and unit.is_player:
		for child in get_tree().get_root().get_children():
			if child is CanvasLayer and child.get_script().resource_path == "res://GUI/PlayerInventory/Scripts/player_inventory_menu.gd":
				if child.unit == unit:
					child.queue_free()
					break

	for child in get_children():
		if child.get_script() and child.get_script().resource_path == "res://GUI/ItemMenus/selected_item_menu.gd":
			child.queue_free()
			break

	queue_free()
