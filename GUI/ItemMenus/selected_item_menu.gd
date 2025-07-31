#selected_item_menu.gd
extends Control  # Or PopupPanel, etc.
class_name SelectedItemMenu
static var active_popup: Control = null
static var pending_trade_data := {}
var opened_from_summary: bool = false
var slot: SlotData
var unit: Unit

var source: String  # "inventory" or "held_items"
var game_board: GameBoard       # Assigned when creating the popup
var source_button: Button
var side: String = "A" 

func _ready():
	# Close any existing popups
	if active_popup and active_popup != self:
		active_popup.queue_free()
	if StoreItemMenu.active_store_popup:
		StoreItemMenu.active_store_popup.queue_free()
	if HoldItemMenu.active_hold_popup:
		HoldItemMenu.active_hold_popup.queue_free()

	active_popup = self
	set_process_unhandled_input(true)

	# Connect button signals
	$VBoxContainer/EquipButton.pressed.connect(_on_equip_button_pressed)
	$VBoxContainer/HoldButton.pressed.connect(_on_hold_button_pressed)
	$VBoxContainer/TradeButton.pressed.connect(_on_trade_button_pressed)
	$VBoxContainer/StoreButton.pressed.connect(_on_store_button_pressed)
	$VBoxContainer/CloseButton.pressed.connect(_on_close_button_pressed)
	$VBoxContainer/UseButton.pressed.connect(_on_use_button_pressed)
	$VBoxContainer/DescriptionButton.pressed.connect(_on_description_button_pressed)

	# Show hold button only when source is inventory
	# Show Hold button only if there's a HeldItemsMenu on screen AND its unit's held_items is not full
	var show_hold := false

	if source == "inventory":
		for child in get_tree().get_root().get_children():
			if child is HeldItemsMenu and child.unit and child.unit.held_items:
				if not child.unit.held_items.is_full():
					show_hold = true
					break

	$VBoxContainer/HoldButton.visible = show_hold


	# Show store button only when source is "held_items" AND there's only 1 HeldItemsMenu
	var held_items_count := 0
	for child in get_tree().get_root().get_children():
		if child is HeldItemsMenu:
			held_items_count += 1
	$VBoxContainer/StoreButton.visible = (source == "held_items" and held_items_count == 1)

	# Trade button logic
	var trade_visible := false
	if source == "inventory":
		trade_visible = true
	elif unit and unit.is_player:
		trade_visible = true
	elif unit and not unit.is_player and game_board:
		var unit_cell = unit.grid.calculate_grid_coordinates(unit.position)
		var DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
		for dir in DIRECTIONS:
			var neighbor_cell = unit_cell + dir
			if game_board._units.has(neighbor_cell):
				var neighbor = game_board._units[neighbor_cell]
				if not neighbor.is_enemy:
					trade_visible = true
					break
	$VBoxContainer/TradeButton.visible = trade_visible

	var is_equippable := slot.item_data is WeaponItemData or slot.item_data is EquipmentItemData
	$VBoxContainer/EquipButton.visible = is_equippable and source != "inventory"
# Change Equip button text to "Unequip" if the item is currently equipped
	if is_equippable and source != "inventory":
		if slot.item_data.equipped:
			$VBoxContainer/EquipButton.text = "UNEQUIP"
			
		else:
			$VBoxContainer/EquipButton.text = "EQUIP"

	if opened_from_summary:
		for button in $VBoxContainer.get_children():
			match button.name:
				"CloseButton", "DescriptionButton":
					button.visible = true
				"EquipButton":
				# Show Equip only if item is equippable and source != inventory (your existing logic)
					button.visible = (slot.item_data is WeaponItemData or slot.item_data is EquipmentItemData) and source != "inventory"
				_:
					button.visible = false

	# Use button visibility
	$VBoxContainer/UseButton.visible = slot.item_data is ProvisionItemData

	if not unit or not game_board:
		return

  
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if not get_global_rect().has_point(get_viewport().get_mouse_position()):
			if pending_trade_data.has("slot"):
				print("Trade cancelled.")
				pending_trade_data.clear()

				# Restore buttons
				for child in $VBoxContainer.get_children():
					child.modulate.a = 1.0
					child.mouse_filter = Control.MOUSE_FILTER_STOP

				return  # Don’t close the popup anymore
			queue_free()


func _on_close_button_pressed() -> void:
	if pending_trade_data.has("slot"):
		print("Trade cancelled.")
		pending_trade_data.clear()
	queue_free()


func _on_store_button_pressed() -> void:
	var store_menu_scene = preload("res://GUI/HeldItems/Scenes/store_item_menu.tscn")
	var store_menu = store_menu_scene.instantiate()
	store_menu.unit = unit
	store_menu.slot = slot

	# Pass the actual Store button node so store menu can position relative to it
	store_menu.store_button = $VBoxContainer/StoreButton

	# Add store_menu as sibling to this popup so layering/order remains consistent
	get_parent().add_child(store_menu)

	# Position store_menu relative to the StoreButton's global position
	if store_menu.store_button:
		var button_global_pos = store_menu.store_button.get_global_position()
		var offset = Vector2(-65, -35)  # tweak this to position the store_menu nicely to the right or left
		store_menu.global_position = button_global_pos + offset
	else:
		# fallback positioning
		store_menu.global_position = global_position + Vector2(0, 0)


func _on_hold_button_pressed() -> void:
	var hold_item_menu_scene = preload("res://GUI/PlayerInventory/Scenes/hold_item_menu.tscn")
	var hold_item_menu = hold_item_menu_scene.instantiate()
	hold_item_menu.unit = unit
	hold_item_menu.slot = slot

	# Pass the source button (HoldButton) so hold_item_menu can position relative to it
	hold_item_menu.source_button = $VBoxContainer/HoldButton

	# Add hold_item_menu as sibling to this popup for layering
	get_parent().add_child(hold_item_menu)

	# Position hold_item_menu relative to the HoldButton's global position
	if hold_item_menu.source_button:
		var button_global_pos = hold_item_menu.source_button.get_global_position()
		var offset = Vector2(65, -35)  # Adjust offset as needed
		hold_item_menu.global_position = button_global_pos + offset
	else:
		# fallback positioning
		hold_item_menu.global_position = global_position + Vector2(0, 0)




func _on_trade_button_pressed() -> void:
	# Store this slot as the first half of the trade
	pending_trade_data = {
		"slot": slot,
		"unit": unit,
		"source": source,
		"source_button": source_button,
		"game_board": game_board
	}

	# Notify the user (you can make this a real visual hint later)
	print("Trade started. Select another item to swap with.")

	# Close this menu, wait for next item to be selected
	for child in $VBoxContainer.get_children():
		if child != $VBoxContainer/CloseButton:
			child.modulate.a = 0.0
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


#or unequip 
func _on_equip_button_pressed():
	if unit and slot.item_data:
		if slot.item_data.equipped:
			unit.unequip_item(slot.item_data)
		else:
			unit.equip_item(slot.item_data)

		# Refresh the appropriate item menu
		for child in get_tree().get_root().get_children():
			if source == "inventory":
				child.populate_items()
			elif source == "held_items" and child is HeldItemsMenu and child.unit == unit:
				child.populate_items()

		queue_free()



func _on_use_button_pressed() -> void:
	pass

func _on_description_button_pressed() -> void:
	var desc_box_scene = preload("res://GUI/ItemMenus/item_description_box.tscn")
	var desc_box = desc_box_scene.instantiate()
	get_tree().get_root().add_child(desc_box)

	desc_box.show_item_description(slot.item_data)

	if unit and unit.is_player:
		if source == "inventory":
			desc_box.set_position(Vector2(541, 365))
		elif source == "held_items":
			desc_box.set_position(Vector2(350, 365))
		else:
			desc_box.set_position(Vector2(960, 540))
	else:
		desc_box.set_position(Vector2(750, 75))

	desc_box.popup()


func _set_custom_offset(offset: Vector2) -> void:
	position = offset

func _exit_tree():
	if active_popup == self:
		active_popup = null
