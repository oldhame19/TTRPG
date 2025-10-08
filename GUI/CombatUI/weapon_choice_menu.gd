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
var selected_sling_mode: int = SlingWeapon.SlingMode.DEFAULT
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

		button.disabled = not _can_weapon_hit_enemies(weapon)

		var w := weapon

		button.mouse_entered.connect(func():
			_update_forecast_label(w)
			game_board.cursor.center_on_unit(unit)
			if game_board.combat_forecast_panel:
				game_board.combat_forecast_panel.visible = false

			attackable_cells = game_board.get_attackable_cells_for_weapon(unit, w)
			game_board._unit_overlay.clear_attackable_cells()
			game_board._unit_overlay.draw_attackable_cells(attackable_cells)
		)

		button.mouse_exited.connect(func():
			_reset_to_initial_weapon()
		)

		button.pressed.connect(func():
			# If it's a sling, handle mode selection/auto-select
			if w is SlingWeapon:
				var available_modes := _get_available_sling_modes()
				if available_modes.size() > 1:
					_show_sling_mode_choice_menu(w, available_modes)
					return
				elif available_modes.size() == 1:
					# set mode on the weapon *before* equipping so forecasts & calculators pick it up
					w.set_mode(available_modes[0])

			if w != unit.equipped_weapon:
				has_selected_weapon = true
				# ensure unit's equipped reference is the exact instance we modified (important for SlingWeapon modes)
				unit.equip_item(w)
			unit.attack_range = w.atk_range

			# refresh forecast and overlays using the equipped weapon (consistent source)
			_update_forecast_label(unit.equipped_weapon)
			attackable_cells = game_board.get_attackable_cells_for_weapon(unit, unit.equipped_weapon)
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


func _show_sling_mode_choice_menu(sling_weapon: SlingWeapon, available_modes: Array):
	if has_node("SlingModeChoice"):
		return
	var panel = Panel.new()
	panel.name = "SlingModeChoice"
	panel.custom_minimum_size = Vector2(220, 140)
	add_child(panel)
	panel.position = Vector2(300, 200)

	var vbox_menu = VBoxContainer.new()
	panel.add_child(vbox_menu)
	vbox_menu.anchor_right = 1
	vbox_menu.anchor_bottom = 1
	vbox_menu.size_flags_vertical = Control.SIZE_FILL
	vbox_menu.size_flags_horizontal = Control.SIZE_FILL

	for mode in available_modes:
		var btn = Button.new()
		btn.text = _mode_to_ammo_name(mode)
		vbox_menu.add_child(btn)

		# Hover preview: use the sling's forecast helper so no mutation happens
		btn.mouse_entered.connect(func():
			var preview = sling_weapon.get_forecast_with_mode(mode)
			forecast_label.text = "ATK: %d     HIT: %d     CRIT: %d" % [
				preview.power, preview.hit, preview.crit
	]
)


		btn.mouse_exited.connect(func():
			_reset_to_initial_weapon()
		)

		btn.pressed.connect(func():
			# set the mode first (mutates the sling instance)
			sling_weapon.set_mode(mode)

			# ensure the unit is equipping the exact sling instance (so calculators read the new mode)
			has_selected_weapon = true
			unit.equip_item(sling_weapon)
			unit.attack_range = sling_weapon.atk_range

			# update forecasts and overlays using the equipped weapon (consistent)
			_update_forecast_label(unit.equipped_weapon)
			_draw_weapon_attack_cells(unit.equipped_weapon)
			game_board.cursor.process_mode = Node.PROCESS_MODE_INHERIT
			populate_weapons()
			panel.queue_free()
		)

	var close_btn = Button.new()
	close_btn.text = "Cancel"
	vbox_menu.add_child(close_btn)
	close_btn.pressed.connect(func(): panel.queue_free())


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

func _has_sling_ammo() -> bool:
	for ammo_slot in unit.held_items.slots:
		if (ammo_slot.item_data.name == "Jagged Stone" or ammo_slot.item_data.name == "Smooth Stone") and ammo_slot.quantity > 0:
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


func _get_available_sling_modes() -> Array:
	var modes := []
	for ammo_slot in unit.held_items.slots:
		match ammo_slot.item_data.name:
			"Jagged Stone":
				if not modes.has(SlingWeapon.SlingMode.JAGGED):
					modes.append(SlingWeapon.SlingMode.JAGGED)
			"Smooth Stone":
				if not modes.has(SlingWeapon.SlingMode.SMOOTH):
					modes.append(SlingWeapon.SlingMode.SMOOTH)
	return modes


func _mode_to_ammo_name(mode: int) -> String:
	match mode:
		SlingWeapon.SlingMode.JAGGED:
			return "Jagged Stone"
		SlingWeapon.SlingMode.SMOOTH:
			return "Smooth Stone"
		_:
			return "Unknown"
