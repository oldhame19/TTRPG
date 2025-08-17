extends Control
class_name HoldItemMenu

@export var unit: Unit
@export var slot: SlotData  # The slot selected from player inventory
var source_button: Button
static var active_hold_popup: Control = null
static var active_popup: Control = null

func _ready():
	# Close any other active popups of same type
	if active_hold_popup and active_hold_popup != self:
		active_hold_popup.queue_free()
	active_hold_popup = self
	if active_popup and active_popup != self:
		active_popup.queue_free()
	active_popup = self

	set_process_unhandled_input(true)

	# Connect buttons
	$VBoxContainer/HoldOneButton.pressed.connect(_on_hold_one_pressed)
	$VBoxContainer/HoldAllButton.pressed.connect(_on_hold_all_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()

		# Close if clicked outside this menu entirely
		if not get_global_rect().has_point(mouse_pos):
			queue_free()
			return

		var clicked_inside_button = false
		for button_name in ["HoldOneButton", "HoldAllButton", "BackButton"]:
			var btn = $VBoxContainer.get_node(button_name)
			if btn and btn.get_global_rect().has_point(mouse_pos):
				clicked_inside_button = true
				break

		if not clicked_inside_button:
			queue_free()

func _on_back_pressed() -> void:
	queue_free()

func _on_hold_one_pressed() -> void:
	_hold_items(1)
	queue_free()

func _on_hold_all_pressed() -> void:
	_hold_items(slot.quantity)
	queue_free()

func _hold_items(amount_to_hold: int) -> void:
	var held_items = unit.held_items
	var player_inventory = unit.inventory
	var item_data = slot.item_data
	var remaining = min(amount_to_hold, slot.quantity)
	if remaining <= 0:
		return

	var total_transferred = 0

	# Merge into existing stacks in held items
	for held_slot in held_items.slots:
		if held_slot.item_data.name == item_data.name and \
		   held_slot.item_data.durability == item_data.durability:

			var max_stack = held_slot.item_data.stack_size
			var space_left = max_stack - held_slot.quantity
			if space_left > 0:
				var transfer = min(remaining, space_left)
				held_slot.quantity += transfer
				remaining -= transfer
				total_transferred += transfer
				if remaining <= 0:
					break

	# Add as new stack if any remain
	if remaining > 0:
		var new_slot = slot.clone()
		new_slot.quantity = remaining
		held_items.slots.append(new_slot)
		total_transferred += remaining
		remaining = 0

	# Decrement player inventory slot only once after transfers
	# Find actual slot in player inventory and update it
	for i in range(player_inventory.slots.size()):
		var inv_slot = player_inventory.slots[i]
		if inv_slot == slot:
			inv_slot.quantity -= total_transferred
			if inv_slot.quantity <= 0:
				player_inventory.slots.remove_at(i)
			break

	# Refresh menus to update UI
	_refresh_menus()

func _refresh_menus():
	for child in get_tree().get_root().get_children():
		if child is CanvasLayer:
			if child.get_script() and child.get_script().resource_path == "res://GUI/HeldItems/Scripts/held_item_menu.gd":
				child.populate_items()
			elif child.get_script() and child.get_script().resource_path == "res://GUI/PlayerInventory/Scripts/player_inventory_menu.gd":
				child.populate_items()  # Show all

func _exit_tree():
	if active_popup == self:
		active_popup = null
	if active_hold_popup == self:
		active_hold_popup = null
