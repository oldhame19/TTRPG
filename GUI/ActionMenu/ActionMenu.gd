extends CanvasLayer
@onready var cursor: Cursor = get_parent()._cursor

var unit        # assign before _ready runs
var game_board  # assign before _ready runs

func _ready() -> void:
	$VBoxContainer/AttackButton.grab_focus()
	
	cursor.hide()
	cursor.process_mode = Node.PROCESS_MODE_DISABLED

	if not unit:
		return

	if not game_board:
		return

	var unit_cell = unit.grid.calculate_grid_coordinates(unit.position)

	# Check for adjacent allies (existing code)
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	var has_adjacent_ally = false

	for dir in directions:
		var neighbor_cell = unit_cell + dir
		if game_board._units.has(neighbor_cell):
			var neighbor = game_board._units[neighbor_cell]
			if not neighbor.is_enemy:
				has_adjacent_ally = true
				break
	$VBoxContainer/TradeButton.visible = has_adjacent_ally

	# NEW: Check if enemy is within attack range
	var enemy_in_range = false

	# Use flood fill to get cells within attack range ignoring obstacles for simplicity
	var attack_range_cells = game_board._flood_fill(unit_cell, unit.attack_range)

	for cell_pos in attack_range_cells:
		if game_board._units.has(cell_pos):
			var target_unit = game_board._units[cell_pos]
			if target_unit.is_enemy:
				enemy_in_range = true
				break

	$VBoxContainer/AttackButton.visible = enemy_in_range



func _on_attack_button_pressed() -> void:
	pass # Replace with function body.


func _on_trade_button_pressed() -> void:
	pass # Replace with function body.


func _on_action_button_pressed() -> void:
	pass # Replace with function body.

func _on_items_button_pressed() -> void:
	var unit = get_parent()._active_unit
	if not unit:
		return

	if unit.is_player:
		# Load and show the inventory menu (use its editor-set position)
		var inventory_menu = preload("res://GUI/PlayerInventory/Scenes/player_inventory_menu.tscn").instantiate()
		inventory_menu.unit = unit
		get_tree().get_root().add_child(inventory_menu)

		# Load and show the held items menu
		var held_items_menu = preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn").instantiate()
		held_items_menu.unit = unit
		get_tree().get_root().add_child(held_items_menu)

		# Hide the close button in held items menu
		held_items_menu.get_node("Panel/CloseButton").visible = false

		# Only move the held items panel to align next to the inventory
		held_items_menu.get_node("Panel").position = Vector2(201, 73)  # Adjust as needed

		# Hide this action menu until both close
		hide()

		inventory_menu.tree_exited.connect(func():
			if not is_instance_valid(held_items_menu):
				show()
		)
		held_items_menu.tree_exited.connect(func():
			if not is_instance_valid(inventory_menu):
				show()
		)
	else:
		# Non-player units: just show held items
		var held_items_menu = preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn").instantiate()
		held_items_menu.unit = unit
		get_tree().get_root().add_child(held_items_menu)
		hide()
		held_items_menu.tree_exited.connect(func(): show())



func _on_wait_button_pressed() -> void:
	# Set curr_unit to wait status
	# Clear active unit

	get_parent()._clear_active_unit()

	# Enable cursor and close menu
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.reset_cursor()
	cursor.show()
	queue_free()


func _on_cancel_button_pressed() -> void:
	# Reset the unit's position
	get_parent()._reset_unit()

	# Enable cursor and close menu
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.reset_cursor()
	cursor.show()
	queue_free()
