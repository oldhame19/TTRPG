extends CanvasLayer
class_name ActionMenu

@onready var cursor: Cursor = get_parent()._cursor

var DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
var unit: Unit        # assign before _ready runs
var game_board: GameBoard  # assign before _ready runs
var trade_mode_active: bool = false
var attack_mode_active: bool = false
var assist_mode_active: bool = false
var weapon_choice_active: bool = false  # NEW FLAG
var _current_trade_scene: Control = null
var opened_from_summary: bool = false
var _trade_menu_scene := preload("res://GUI/ActionMenu/trade_ui.tscn")

func _ready() -> void:
	$VBoxContainer/AttackButton.grab_focus()

	cursor.hide()
	cursor.process_mode = Node.PROCESS_MODE_DISABLED

	if not unit or not game_board:
		return

	var unit_cell = unit.grid.calculate_grid_coordinates(unit.position)

	# ---------------------
	# Trade button logic
	# ---------------------
	var has_adjacent_ally = false
	for dir in DIRECTIONS:
		var neighbor_cell = unit_cell + dir
		if game_board._units.has(neighbor_cell):
			var neighbor = game_board._units[neighbor_cell]
			if not neighbor.is_enemy:
				has_adjacent_ally = true
				break
	$VBoxContainer/TradeButton.visible = has_adjacent_ally

	# ---------------------
	# Assist button logic
	# ---------------------
	var can_assist := false
	if has_adjacent_ally and unit.current_class and unit.current_class.can_assist:
		can_assist = true
	$VBoxContainer/AssistButton.visible = can_assist

	# ---------------------
	# Attack button logic — now checks ALL weapons in held items
	# ---------------------
	var enemy_in_range = false

	for slot in unit.held_items.slots:
		if slot.item_data is WeaponItemData:
			var weapon := slot.item_data as WeaponItemData

			# Skip unusable weapons for this unit's class
			if weapon.weapon_type not in unit.current_class.allowed_weapon_types:
				continue

			# (Optional) Ammo check — skip sling with no stones
			if weapon.weapon_type == WeaponItemData.WeaponType.SLING:
				var has_stone := false
				for ammo_slot in unit.held_items.slots:
					if ammo_slot.item_data.name == "Stone" and ammo_slot.quantity > 0:
						has_stone = true
						break
				if not has_stone:
					continue

			# Check weapon's attack range
			var weapon_range_cells = game_board._flood_fill(unit_cell, weapon.atk_range)
			for cell_pos in weapon_range_cells:
				if game_board._units.has(cell_pos):
					var target_unit = game_board._units[cell_pos]
					if target_unit.is_enemy:
						enemy_in_range = true
						break
			if enemy_in_range:
				break

	$VBoxContainer/AttackButton.visible = enemy_in_range

func _on_attack_button_pressed() -> void:
	attack_mode_active = true
	weapon_choice_active = true  # NEW FLAG
	game_board._unit_info_panel.visible = false

	if not unit or not game_board:
		return

	var menu = preload("res://GUI/CombatUI/weapon_choice_menu.tscn").instantiate()
	menu.unit = unit
	menu.game_board = game_board
	menu.get_node("Panel").position = Vector2(750, 50)
	get_tree().get_root().add_child(menu)
	hide()

	menu.close_active_modes.connect(func():
		attack_mode_active = false
		weapon_choice_active = false  # reset flag
		trade_mode_active = false
		assist_mode_active = false
	)

	menu.tree_exited.connect(func():
		show()
	)


func _on_assist_button_pressed() -> void:

	game_board._unit_info_panel.visible = false
	if unit == null or unit.grid == null:
		game_board._reinitialize()

	var assistable_cells = game_board.get_assistable_cells(unit)
	game_board._unit_overlay.draw_assistable_cells(assistable_cells)
	assist_mode_active = true

	for button in $VBoxContainer.get_children():
		if button.name != "CancelButton":
			button.visible = false

	cursor.show()
	cursor.set_allowed_cells(assistable_cells)
	cursor.process_mode = Node.PROCESS_MODE_INHERIT

	cursor.show_sprite = true
	cursor.set_pointer_visible(false)
	pass # Replace with function body.

func _on_trade_button_pressed() -> void:
	game_board._unit_info_panel.visible = false
	if unit == null or unit.grid == null:
		game_board._reinitialize()

	var tradeable_cells = game_board.get_tradeable_cells(unit)
	game_board._unit_overlay.draw_tradeable_cells(tradeable_cells)
	trade_mode_active = true

	for button in $VBoxContainer.get_children():
		if button.name != "CancelButton":
			button.visible = false

	cursor.show()
	cursor.set_allowed_cells(tradeable_cells)
	cursor.process_mode = Node.PROCESS_MODE_INHERIT

	cursor.show_sprite = true
	cursor.set_pointer_visible(false)

func _on_action_button_pressed() -> void:
	game_board._unit_info_panel.visible = false

	pass # Replace with function body.

func _on_items_button_pressed() -> void:
	game_board._unit_info_panel.visible = false
	var selected_unit = get_parent()._active_unit
	if not selected_unit:
		return

	if selected_unit.is_player:
		# PLAYER: Show player inventory + held items
		var inventory_menu = preload("res://GUI/PlayerInventory/Scenes/player_inventory_menu.tscn").instantiate()
		inventory_menu.game_board = game_board
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
			inventory_menu.game_board = game_board
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
	

func _on_summary_button_pressed() -> void:
	var selected_unit = get_parent()._active_unit
	if not selected_unit:
		return

	# Show held items menu (right side)
	var held_items_menu = preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn").instantiate()
	held_items_menu.unit = selected_unit
	held_items_menu.game_board = game_board
	held_items_menu.opened_from_summary = true
	get_tree().get_root().add_child(held_items_menu)
	held_items_menu.get_node("Panel/CloseButton").visible = false
	held_items_menu.get_node("Panel").position = Vector2(750, 73)

	# Show unit stats box (left side)
	var stat_box_scene = preload("res://GUI/UnitInfo/unit_stats_box.tscn")
	var stat_box = stat_box_scene.instantiate()
	add_child(stat_box)
	stat_box.position = Vector2(45, 440)

	# Ensure stats are valid before showing them
	if selected_unit.current_stats:
		stat_box.show_unit_stats(selected_unit.current_stats)
	else:
		stat_box.show_unit_stats(selected_unit.current_stats) 
	opened_from_summary = true

	# Hide all buttons except Cancel
	for button in $VBoxContainer.get_children():
		if button.name != "CancelButton":
			button.visible = false

	# Restore buttons when menus close
	var check_restore := func():
		if not is_instance_valid(held_items_menu) and not is_instance_valid(stat_box):
			for button in $VBoxContainer.get_children():
				button.visible = true

	held_items_menu.tree_exited.connect(check_restore)
	stat_box.tree_exited.connect(check_restore)


func _on_cancel_button_pressed() -> void:
	if attack_mode_active:
		attack_mode_active = false
		game_board._unit_overlay.clear_attackable_cells()
	if assist_mode_active:
		assist_mode_active = false
		game_board._unit_overlay.clear_assistable_cells()
	if trade_mode_active:
		trade_mode_active = false
		game_board._unit_overlay.clear_tradeable_cells()

		# Restore buttons
		for button in $VBoxContainer.get_children():
			button.visible = true
		$VBoxContainer/CancelButton.visible = true

		# Reset cursor
		cursor.restricted_cells.clear()
		cursor.reset_cursor()
		cursor.set_pointer_visible(true)
		cursor.hide()
		cursor.process_mode = Node.PROCESS_MODE_DISABLED

		# Restore unit info panel
		if game_board._unit_info_panel and game_board._active_unit:
			#game_board._unit_info_panel.update_info(game_board._active_unit)
			game_board._unit_info_panel.visible = true
			

	elif opened_from_summary:
		# Remove summary UI elements
		for child in get_tree().get_root().get_children():
			if child is HeldItemsMenu:
				child.queue_free()
		for child in get_children():
			if child is UnitStatsBox:
				child.queue_free()

		# Restore buttons
		for button in $VBoxContainer.get_children():
			button.visible = true
		$VBoxContainer/CancelButton.visible = true

		# Keep action menu open, hide cursor
		cursor.hide()
		cursor.process_mode = Node.PROCESS_MODE_DISABLED
		cursor.restricted_cells.clear()
		cursor.reset_cursor()
		cursor.set_pointer_visible(true)

		# Restore unit info panel
		if game_board._unit_info_panel and game_board._active_unit:
			#game_board._unit_info_panel.update_info(game_board._active_unit)
			game_board._unit_info_panel.visible = true

		opened_from_summary = false

	else:
		# Default behavior — back to board
		get_parent()._reset_unit()

		cursor.restricted_cells.clear()
		cursor.reset_cursor()
		cursor.set_pointer_visible(true)
		cursor.show()
		cursor.process_mode = Node.PROCESS_MODE_INHERIT

		# Clear lingering UI
		for child in get_tree().get_root().get_children():
			if child is HeldItemsMenu:
				child.queue_free()

		# Restore unit info panel
		#if game_board._unit_info_panel and game_board._active_unit:
			#game_board._unit_info_panel.visible = true

		queue_free()

func in_an_active_mode() -> bool:
	return attack_mode_active or assist_mode_active or trade_mode_active
