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

	# Save original weapon & attack range
	original_weapon = unit.equipped_weapon
	original_attack_range = unit.attack_range

	forecast_label.text = "ATK:   --     HIT:   --     CRIT:   -- "

	# Close button pressed
	close_button.pressed.connect(func():
		close_active_modes.emit()

		if has_selected_weapon:
			# Restore original weapon and attack range if no weapon selected
			if original_weapon:
				unit.equip_item(original_weapon)
			else:
				unit.unequip_item(unit.equipped_weapon)
				unit.attack_range = original_attack_range

		game_board._unit_overlay.clear_attackable_cells()
		game_board._unit_info_panel.visible = true
		game_board.combat_forecast_panel.visible = false
		queue_free()
	)

	# Close button hover hides panels
	close_button.mouse_entered.connect(func():
		game_board.cursor.center_on_unit(unit)
		if game_board._unit_info_panel:
			game_board._unit_info_panel.visible = false
		if game_board.combat_forecast_panel:
			game_board.combat_forecast_panel.visible = false
	)

	populate_weapons()

func populate_weapons():

	# Clear existing buttons
	for child in vbox.get_children():
		child.queue_free()

	var weapon_slots = unit.held_items.get_all_weapon_items()

	# Sort so equipped weapon is at the top
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

		button.mouse_entered.connect(func():
			var hover_forecast := CombatCalculator.get_combat_forecast(unit, null, weapon)
			forecast_label.text = "ATK: %s     HIT: %s     CRIT: %s" % [
				str(hover_forecast.attack),
				str(hover_forecast.hit),
				str(hover_forecast.crit)
			]

			game_board.cursor.center_on_unit(unit)
			game_board.combat_forecast_panel.visible = false
			game_board._unit_info_panel.visible = false

	# === Draw temporary attackable cells using hovered weapon range ===
			var old_attack_range = unit.attack_range
			unit.attack_range = weapon.atk_range
			attackable_cells = game_board.get_attackable_cells(unit)
			unit.attack_range = old_attack_range

			game_board._unit_overlay.clear()
			game_board._unit_overlay.draw_attackable_cells(attackable_cells)
		)




		button.mouse_exited.connect(func():
			# Restore label to currently equipped weapon
			if unit.equipped_weapon:
				var equipped_forecast := CombatCalculator.get_combat_forecast(unit, null, unit.equipped_weapon)
				forecast_label.text = "ATK: %s     HIT: %s     CRIT: %s" % [
					str(equipped_forecast.attack),
					str(equipped_forecast.hit),
					str(equipped_forecast.crit)
				]
				unit.attack_range = unit.equipped_weapon.atk_range
				attackable_cells = game_board.get_attackable_cells(unit)
				game_board._unit_overlay.clear()
				game_board._unit_overlay.draw_attackable_cells(attackable_cells)
			else:
				forecast_label.text = "ATK: --     HIT: --     CRIT: --"
				attackable_cells = []
				game_board._unit_overlay.clear()
			
		)

		# Pressing a weapon equips it and updates overlay
		button.pressed.connect(func():
			if weapon != unit.equipped_weapon:
				has_selected_weapon = true
				unit.equip_item(weapon)
			unit.attack_range = weapon.atk_range
			

			game_board._unit_overlay.clear()
			attackable_cells = game_board.get_attackable_cells(unit)
			game_board._unit_overlay.draw_attackable_cells(attackable_cells)
			game_board.cursor.set_allowed_cells(attackable_cells)
			game_board.cursor.hide()
			game_board.cursor.process_mode = Node.PROCESS_MODE_INHERIT
			game_board.cursor.show_sprite = true
			game_board.cursor.set_pointer_visible(false)
			game_board.cursor.center_on_unit(unit)

			game_board._unit_info_panel.visible = false
			# Main forecast panel still hidden
			game_board.combat_forecast_panel.visible = false

			populate_weapons()
			
			await get_tree().create_timer(0.05).timeout
			
		)

		vbox.add_child(button)
