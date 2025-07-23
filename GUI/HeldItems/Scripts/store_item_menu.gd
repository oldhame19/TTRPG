#store_item_menu.gd
class_name StoreItemMenu
extends Control
var selected_item_menu: Control = null
static var active_store_popup: Control = null

@export var unit: Unit
@export var slot: SlotData
var source_button: Button
static var active_popup: Control = null
var store_button: Button
func _ready():
		# Close any other active popup of the same type
	if active_store_popup and active_store_popup != self:
		active_store_popup.queue_free()
	active_store_popup = self
	# Close any other active popup of the same type
	if active_popup and active_popup != self:
		active_popup.queue_free()
	active_popup = self
	set_process_unhandled_input(true)

	# Connect buttons (if not already connected in the scene)
	$VBoxContainer/StoreOneButton.pressed.connect(_on_store_one_button_pressed)
	$VBoxContainer/StoreAllButton.pressed.connect(_on_store_all_button_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	queue_free()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()

		# If click is outside this menu entirely, close
		if not get_global_rect().has_point(mouse_pos):
			queue_free()
			return

		# Otherwise, check if click was inside any of the 3 buttons, allow if yes
		var clicked_inside_button = false
		for button_name in ["StoreOneButton", "StoreAllButton", "BackButton"]:
			var btn = $VBoxContainer.get_node(button_name)
			if btn and btn.get_global_rect().has_point(mouse_pos):
				clicked_inside_button = true
				break

		# If click was NOT inside any of the buttons, close the menu
		if not clicked_inside_button:
			queue_free()
func _on_store_one_button_pressed() -> void:
	_store_items(1)
	queue_free()

func _on_store_all_button_pressed() -> void:
	_store_items(slot.quantity)
	queue_free()

func _store_items(amount_to_store: int) -> void:
	var player_inventory := unit.inventory
	var held_items := unit.held_items
	var item_data := slot.item_data
	var remaining: int = min(amount_to_store, slot.quantity)  # can't store more than held

	if remaining <= 0:
		return  # nothing to store

	var total_transferred: int = 0

	# Merge into existing stacks in player inventory
	for inv_slot in player_inventory.slots:
		if inv_slot.item_data == item_data and inv_slot.item_data.durability == item_data.durability:
			var max_stack: int = item_data.stack_size
			var space_left: int = max_stack - inv_slot.quantity
			if space_left > 0:
				var transfer: int = min(remaining, space_left)
				inv_slot.quantity += transfer
				remaining -= transfer
				total_transferred += transfer
				if remaining <= 0:
					break

	# Add as new stack if any remain
	if remaining > 0:
		# Create a new SlotData clone for the new stack
		var new_slot := slot.clone()  # This should produce a new SlotData instance with same item_data and quantity
		new_slot.quantity = remaining  # Set quantity to the remaining amount to store
		player_inventory.slots.append(new_slot)
		total_transferred += remaining
		remaining = 0

	# Decrement held item slot only once, after all transfers
	slot.quantity -= total_transferred

	# Remove slot from held items if empty or below zero (prevent negatives)
	if slot.quantity <= 0:
		slot.quantity = 0
		if held_items.slots.has(slot):
			held_items.slots.erase(slot)

	# Refresh UI menus to reflect changes
	_refresh_menus()


func _refresh_menus():
	for child in get_tree().get_root().get_children():
		if child is CanvasLayer:
			if child.get_script() and child.get_script().resource_path == "res://GUI/HeldItems/Scripts/held_item_menu.gd":
				child.populate_items()
			elif child.get_script() and child.get_script().resource_path == "res://GUI/PlayerInventory/Scripts/player_inventory_menu.gd":
				child.populate_items(-1)  # Show all

func _exit_tree():
	if active_popup == self:
		active_popup = null
	if active_store_popup == self:
		active_store_popup = null
