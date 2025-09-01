extends CanvasLayer
class_name WeaponChoiceMenu

@onready var panel := $Panel
@onready var vbox := $Panel/VBoxContainer
@onready var close_button := $Panel/CloseButton
@onready var forecast_label := $Panel/ForecastLabel

signal close_active_modes
var unit: Unit
var game_board: GameBoard
var attackable_cells := []
var position_on_screen: Vector2 = Vector2(100, 100)
var selected_sling_ammo_name: String = ""
var original_weapon: WeaponItemData
var original_attack_range: int
var has_selected_weapon := false

func _ready():
	panel.add_to_group("ui_weapon_choice")

	original_weapon = unit.equipped_weapon
	original_attack_range = unit.attack_range

	# Show equipped weapon forecast if one is equipped, otherwise dashes
	if unit.equipped_weapon:
		_update_forecast_label(unit.equipped_weapon)
	else:
		forecast_label.text = "ATK: --     HIT: --     CRIT: --"

	close_button.pressed.connect(func():
		close_active_modes.emit()

		if has_selected_weapon:
			if original_weapon:
				unit.equip_item(original_weapon)
			else:
				unit.unequip_item(unit.equipped_weapon)
				unit.attack_range = original_attack_range

		game_board.cursor.center_on_unit(unit)
		game_board._unit_overlay.clear_attackable_cells()
		if game_board._unit_info_panel:
			game_board._unit_info_panel.visible = true
		if game_board.combat_forecast_panel:
			game_board.combat_forecast_panel.visible = false
		
		queue_free()
	)

	populate_weapons()

	# Show attack cells for equipped or longest range usable weapon
	var weapon_to_show = original_weapon if _can_weapon_hit_enemies(original_weapon) else _get_longest_range_weapon()
	if weapon_to_show:
		_draw_weapon_attack_cells(weapon_to_show)
	else:
		game_board._unit_overlay.clear_attackable_cells()


func populate_weapons():
	for child in vbox.get_children():
		child.queue_free()

	var weapon_slots = unit.held_items.get_all_weapon_items()

	if not has_selected_weapon:
		weapon_slots.sort_custom(func(a, b):
			return (a.item_data == unit.equipped_weapon) > (b.item_data == unit.equipped_weapon)
		)

	for slot in weapon_slots:
		var weapon := slot.item_data as WeaponItemData
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 40)

		var equipped_indicator = " [E] " if weapon == unit.equipped_weapon else ""
		button.text = "%s%s   %d/%d" % [
			equipped_indicator,
			weapon.name,
			weapon.durability,
			weapon.max_durability
		]

		var can_hit_enemy := false

		if unit.current_class and weapon.weapon_type in unit.current_class.allowed_weapon_types:
			if weapon.weapon_type != WeaponItemData.WeaponType.SLING or _has_sling_ammo():
				var unit_cell = unit.grid.calculate_grid_coordinates(unit.position)
				var weapon_range_cells = game_board._flood_fill(unit_cell, weapon.atk_range)

				for cell_pos in weapon_range_cells:
					if game_board._units.has(cell_pos):
						var target_unit = game_board._units[cell_pos]
						if target_unit.is_enemy:
							can_hit_enemy = true
							break

		button.disabled = not can_hit_enemy

		var w := weapon

		button.mouse_entered.connect(func():
			# Show hovered weapon forecast
			_update_forecast_label(w)

			game_board.cursor.center_on_unit(unit)
			if game_board.combat_forecast_panel:
				game_board.combat_forecast_panel.visible = false

			attackable_cells = game_board.get_attackable_cells_for_weapon(unit, w)
			game_board._unit_overlay.clear_attackable_cells()
			game_board._unit_overlay.draw_attackable_cells(attackable_cells)
		)

		button.mouse_exited.connect(func():
			# Return to showing equipped weapon forecast if available
			if unit.equipped_weapon:
				_update_forecast_label(unit.equipped_weapon)
				if _can_weapon_hit_enemies(unit.equipped_weapon):
					_draw_weapon_attack_cells(unit.equipped_weapon)
				else:
					var longest_weapon = _get_longest_range_weapon()
					if longest_weapon:
						_draw_weapon_attack_cells(longest_weapon)
					else:
						game_board._unit_overlay.clear_attackable_cells()
			else:
				var longest_weapon = _get_longest_range_weapon()
				if longest_weapon:
					forecast_label.text = "ATK: --     HIT: --     CRIT: --"
					_draw_weapon_attack_cells(longest_weapon)
				else:
					forecast_label.text = "ATK: --     HIT: --     CRIT: --"
					game_board._unit_overlay.clear_attackable_cells()
		)

		button.pressed.connect(func():
			if w.weapon_type == WeaponItemData.WeaponType.SLING:
				var ammo_types := []
				for ammo_slot in unit.held_items.slots:
					if ammo_slot.item_data.name in ["Jagged Stone", "Smooth Stone"] and ammo_slot.quantity > 0:
						ammo_types.append(ammo_slot.item_data.name)
				if ammo_types.size() > 1:
					_show_sling_ammo_choice_menu(w, ammo_types)
					return  # wait for player to pick ammo
				elif ammo_types.size() == 1:
					selected_sling_ammo_name = ammo_types[0]
			if w != unit.equipped_weapon:
				has_selected_weapon = true
				unit.equip_item(w)
			unit.attack_range = w.atk_range

			_update_forecast_label(w)
			attackable_cells = game_board.get_attackable_cells_for_weapon(unit, w)
			game_board._unit_overlay.clear_attackable_cells()
			game_board._unit_overlay.draw_attackable_cells(attackable_cells)

			game_board.cursor.set_allowed_cells(attackable_cells)
			game_board.cursor.hide()
			game_board.cursor.process_mode = Node.PROCESS_MODE_INHERIT
			game_board.cursor.show_sprite = true
			game_board.cursor.set_pointer_visible(false)
			game_board.cursor.center_on_unit(unit)

			if game_board.combat_forecast_panel:
				game_board.combat_forecast_panel.visible = false

			populate_weapons()
			await get_tree().create_timer(0.05).timeout
		)

		vbox.add_child(button)

func _show_sling_ammo_choice_menu(weapon: WeaponItemData, ammo_types: Array):
	var menu_panel = Panel.new()
	menu_panel.name = "SlingAmmoChoice"
	menu_panel.custom_minimum_size = Vector2(200, 120)
	add_child(menu_panel)
	menu_panel.position = Vector2(300, 200)

	var vbox_menu = VBoxContainer.new()
	menu_panel.add_child(vbox_menu)
	vbox_menu.anchor_right = 1
	vbox_menu.anchor_bottom = 1
	vbox_menu.size_flags_vertical = Control.SIZE_FILL
	vbox_menu.size_flags_horizontal = Control.SIZE_FILL

	# Ammo buttons
	for ammo_name in ammo_types:
		var ammo_btn = Button.new()
		ammo_btn.text = ammo_name
		vbox_menu.add_child(ammo_btn)

		# Hover preview
		ammo_btn.mouse_entered.connect(func():
			if weapon is SlingWeapon:
				var current_ammo = weapon.get_selected_ammo()
				
				weapon._reset_to_base_stats()
				weapon._apply_ammo_stats(ammo_name)
				_update_forecast_label(weapon)

		# IMPORTANT: reset back so we don’t actually equip it yet
				weapon._reset_to_base_stats()
				if weapon.get_selected_ammo() != "":
					weapon.set_ammo(current_ammo)
		)

		# Reset forecast when leaving button
		ammo_btn.mouse_exited.connect(func():
			#_update_forecast_label(weapon)
			forecast_label.text = "ATK: --     HIT: --     CRIT: --"
		)

		# Selection
		ammo_btn.pressed.connect(func():
			selected_sling_ammo_name = ammo_name
			has_selected_weapon = true
			
			if weapon is SlingWeapon:
				weapon._reset_to_base_stats()
				weapon.set_ammo(ammo_name)

			unit.equip_item(weapon)
			unit.attack_range = weapon.atk_range

			# Update forecast and overlays
			_update_forecast_label(weapon)
			attackable_cells = game_board.get_attackable_cells_for_weapon(unit, weapon)
			game_board._unit_overlay.clear_attackable_cells()
			game_board._unit_overlay.draw_attackable_cells(attackable_cells)
			game_board.cursor.set_allowed_cells(attackable_cells)
			game_board.cursor.show_sprite = true
			game_board.cursor.set_pointer_visible(false)

			# Refresh weapon list to update "[E]" indicator
			populate_weapons()

			menu_panel.queue_free()
		)

	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close"
	vbox_menu.add_child(close_btn)
	close_btn.mouse_entered.connect(func():
	# explicitly do nothing so forecast stays whatever it was
		pass
)
	close_btn.pressed.connect(func():
		menu_panel.queue_free())



func _can_weapon_hit_enemies(weapon: WeaponItemData) -> bool:
	if not weapon:
		return false
	if not weapon.weapon_type in unit.current_class.allowed_weapon_types:
		return false
	if weapon.weapon_type == WeaponItemData.WeaponType.SLING and not _has_sling_ammo():
		return false

	var unit_cell = unit.grid.calculate_grid_coordinates(unit.position)
	var weapon_range_cells = game_board._flood_fill(unit_cell, weapon.atk_range)
	for cell_pos in weapon_range_cells:
		if game_board._units.has(cell_pos):
			var target_unit = game_board._units[cell_pos]
			if target_unit.is_enemy:
				return true
	return false


func _get_first_usable_weapon() -> WeaponItemData:
	var weapon_slots = unit.held_items.get_all_weapon_items()
	for slot in weapon_slots:
		var weapon = slot.item_data as WeaponItemData
		if _can_weapon_hit_enemies(weapon):
			return weapon
	return null


func _get_longest_range_weapon() -> WeaponItemData:
	var weapon_slots = unit.held_items.get_all_weapon_items()
	var best_weapon: WeaponItemData = null
	var best_range := -1
	for slot in weapon_slots:
		var weapon = slot.item_data as WeaponItemData
		if _can_weapon_hit_enemies(weapon):
			if weapon.atk_range > best_range:
				best_range = weapon.atk_range
				best_weapon = weapon
	return best_weapon


func _draw_weapon_attack_cells(weapon: WeaponItemData) -> void:
	if not weapon:
		game_board._unit_overlay.clear_attackable_cells()
		return

	attackable_cells = game_board.get_attackable_cells_for_weapon(unit, weapon)
	game_board._unit_overlay.clear_attackable_cells()
	game_board._unit_overlay.draw_attackable_cells(attackable_cells)


func _update_forecast_label(weapon: WeaponItemData) -> void:
	if not weapon:
		forecast_label.text = "ATK: --     HIT: --     CRIT: --"
		return
	var forecast = CombatCalculator.get_combat_forecast(unit, null, weapon)
	forecast_label.text = "ATK: %s     HIT: %s     CRIT: %s" % [
		str(forecast.attack),
		str(forecast.hit),
		str(forecast.crit)
	]


func _reset_to_initial_weapon():
	if unit.equipped_weapon:
		_update_forecast_label(unit.equipped_weapon)
		_draw_weapon_attack_cells(unit.equipped_weapon)
	else:
		var longest_weapon = _get_longest_range_weapon()
		if longest_weapon:
			_update_forecast_label(longest_weapon)
			_draw_weapon_attack_cells(longest_weapon)
		else:
			forecast_label.text = "ATK: --     HIT: --     CRIT: --"
			attackable_cells = []
			game_board._unit_overlay.clear_attackable_cells()


func _has_sling_ammo() -> bool:
	for ammo_slot in unit.held_items.slots:
		if (ammo_slot.item_data.name == "Jagged Stone" or ammo_slot.item_data.name == "Smooth Stone") and ammo_slot.quantity > 0:
			return true
	return false
