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

var original_weapon: WeaponItemData
var original_attack_range: int
var has_selected_weapon := false


func _ready():
	panel.add_to_group("ui_weapon_choice")

	original_weapon = unit.equipped_weapon
	original_attack_range = unit.attack_range

	forecast_label.text = "ATK:   --     HIT:   --     CRIT:   -- "

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
		game_board._unit_info_panel.visible = true
		game_board.combat_forecast_panel.visible = false
		
		queue_free()
	)

	#close_button.mouse_entered.connect(func():
		#game_board.cursor.center_on_unit(unit)
		#if game_board._unit_info_panel:
			#game_board._unit_info_panel.visible = false
		#if game_board.combat_forecast_panel:
			#game_board.combat_forecast_panel.visible = false
	#)

	populate_weapons()

	var weapon_to_show = original_weapon if _can_weapon_hit_enemies(original_weapon) else _get_first_usable_weapon()
	if weapon_to_show:
		_draw_weapon_attack_cells(weapon_to_show)
		_update_forecast_label(weapon_to_show)
	else:
		forecast_label.text = "ATK: --     HIT: --     CRIT: --"
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

		if weapon.weapon_type in unit.current_class.allowed_weapon_types:
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

		button.mouse_entered.connect(func():
			var hover_forecast := CombatCalculator.get_combat_forecast(unit, null, weapon)
			forecast_label.text = "ATK: %s     HIT: %s     CRIT: %s" % [
				str(hover_forecast.attack),
				str(hover_forecast.hit),
				str(hover_forecast.crit)
			]

			game_board.cursor.center_on_unit(unit)
			game_board.combat_forecast_panel.visible = false
			#game_board._unit_info_panel.visible = false

			attackable_cells = game_board.get_attackable_cells_for_weapon(unit, weapon)

			game_board._unit_overlay.clear()
			game_board._unit_overlay.draw_attackable_cells(attackable_cells)
		)

		button.mouse_exited.connect(func():
			_reset_to_initial_weapon()
		)

		button.pressed.connect(func():
			if weapon != unit.equipped_weapon:
				has_selected_weapon = true
				unit.equip_item(weapon)
			unit.attack_range = weapon.atk_range

			attackable_cells = game_board.get_attackable_cells_for_weapon(unit, weapon)
			game_board._unit_overlay.clear()
			game_board._unit_overlay.draw_attackable_cells(attackable_cells)

			game_board.cursor.set_allowed_cells(attackable_cells)
			game_board.cursor.hide()
			game_board.cursor.process_mode = Node.PROCESS_MODE_INHERIT
			game_board.cursor.show_sprite = true
			game_board.cursor.set_pointer_visible(false)
			game_board.cursor.center_on_unit(unit)

			#game_board._unit_info_panel.visible = false
			game_board.combat_forecast_panel.visible = false

			populate_weapons()
			await get_tree().create_timer(0.05).timeout
		)

		vbox.add_child(button)

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


func _draw_weapon_attack_cells(weapon: WeaponItemData) -> void:
	attackable_cells = game_board.get_attackable_cells_for_weapon(unit, weapon)

	game_board._unit_overlay.clear()
	game_board._unit_overlay.draw_attackable_cells(attackable_cells)


func _update_forecast_label(weapon: WeaponItemData) -> void:
	var forecast = CombatCalculator.get_combat_forecast(unit, null, weapon)
	forecast_label.text = "ATK: %s     HIT: %s     CRIT: %s" % [
		str(forecast.attack),
		str(forecast.hit),
		str(forecast.crit)
	]


func _reset_to_initial_weapon():
	var weapon_to_show = unit.equipped_weapon if _can_weapon_hit_enemies(unit.equipped_weapon) else _get_first_usable_weapon()
	if weapon_to_show:
		_update_forecast_label(weapon_to_show)
		_draw_weapon_attack_cells(weapon_to_show)
	else:
		forecast_label.text = "ATK: --     HIT: --     CRIT: --"
		attackable_cells = []
		game_board._unit_overlay.clear()





func _has_sling_ammo() -> bool:
	for ammo_slot in unit.held_items.slots:
		if ammo_slot.item_data.name == "Stone" and ammo_slot.quantity > 0:
			return true
	return false
