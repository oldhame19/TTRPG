#ActionMenu.gd
extends CanvasLayer
class_name ActionMenu
@onready var cursor: Cursor = get_parent()._cursor
var DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
var unit        # assign before _ready runs
var game_board  # assign before _ready runs
var trade_mode_active: bool = false
var _current_trade_scene: Control = null
var _trade_menu_scene := preload("res://GUI/ActionMenu/trade_ui.tscn")

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
	
	var has_adjacent_ally = false

	for dir in DIRECTIONS:
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
	var tradeable_cells = game_board.get_tradeable_cells(unit)
	game_board._unit_overlay.draw_tradeable_cells(tradeable_cells)
	trade_mode_active = true

	for button in $VBoxContainer.get_children():
		if button.name != "CancelButton":
			button.visible = false

	cursor.show()
	cursor.set_allowed_cells(tradeable_cells)
	cursor.process_mode = Node.PROCESS_MODE_INHERIT

	cursor.show_sprite = true  # keep outline visible
	cursor.set_pointer_visible(false)  # hide the pointer sprite


func _on_action_button_pressed() -> void:
	pass # Replace with function body.

func _on_items_button_pressed() -> void:
	var selected_unit = get_parent()._active_unit
	if not selected_unit:
		return

	if selected_unit.is_player:
		# PLAYER: Show player inventory + held items
		var inventory_menu = preload("res://GUI/PlayerInventory/Scenes/player_inventory_menu.tscn").instantiate()
		inventory_menu.unit = selected_unit
		get_tree().get_root().add_child(inventory_menu)

		var held_items_menu = preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn").instantiate()
		held_items_menu.unit = selected_unit
		held_items_menu.game_board = game_board
		get_tree().get_root().add_child(held_items_menu)

		held_items_menu.get_node("Panel/CloseButton").visible = false
		held_items_menu.get_node("Panel").position = Vector2(201, 73)
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
		# Check if selected unit is adjacent to the player
		var unit_cell = selected_unit.grid.calculate_grid_coordinates(selected_unit.position)
		var DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
		var adjacent_to_player := false
		var player_unit: Unit = null

		for dir in DIRECTIONS:
			var neighbor_cell = unit_cell + dir
			if game_board._units.has(neighbor_cell):
				var neighbor = game_board._units[neighbor_cell]
				if neighbor.is_player:
					adjacent_to_player = true
					player_unit = neighbor
					break

		if adjacent_to_player and player_unit:
			# Show both: selected unit's held items and player's inventory
			var inventory_menu = preload("res://GUI/PlayerInventory/Scenes/player_inventory_menu.tscn").instantiate()
			inventory_menu.unit = player_unit
			get_tree().get_root().add_child(inventory_menu)

			var held_items_menu = preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn").instantiate()
			held_items_menu.unit = selected_unit
			held_items_menu.game_board = game_board
			get_tree().get_root().add_child(held_items_menu)

			held_items_menu.get_node("Panel/CloseButton").visible = false
			held_items_menu.get_node("Panel").position = Vector2(201, 73)
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
			# Just show held items (normal case)
			var held_items_menu = preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn").instantiate()
			held_items_menu.unit = selected_unit
			held_items_menu.game_board = game_board
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
	if trade_mode_active:
		trade_mode_active = false

		game_board._unit_overlay.clear_tradeable_cells()

		for button in $VBoxContainer.get_children():
			button.visible = true
		$VBoxContainer/CancelButton.visible = true

		cursor.restricted_cells.clear()
		cursor.reset_cursor()
		cursor.set_pointer_visible(true)
		cursor.hide()
		cursor.process_mode = Node.PROCESS_MODE_DISABLED
		return

	# Normal cancel
	get_parent()._reset_unit()
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.restricted_cells.clear()
	cursor.reset_cursor()
	cursor.set_pointer_visible(true)  # just in case
	cursor.show()
	queue_free()
