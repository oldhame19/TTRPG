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
var position_on_screen: Vector2 = Vector2(100, 100)  # Default position (can be set before adding to tree)

func _ready():
	forecast_label.text = "ATK:   --     HIT:   --     CRIT:   -- "
	close_button.pressed.connect(func():
		close_active_modes.emit()
		game_board._unit_overlay.clear_attackable_cells()
		game_board._unit_info_panel.visible = true
		game_board.combat_forecast_panel.visible = false

		queue_free()
	)

	populate_weapons()

func populate_weapons():
	# Clear existing buttons
	for child in vbox.get_children():
		child.queue_free()

	var weapon_slots = unit.held_items.get_all_weapon_items()

	weapon_slots.sort_custom(func(a, b):
		return (a.item_data == unit.equipped_weapon) > (b.item_data == unit.equipped_weapon)
	)

	for slot in weapon_slots:
		var weapon := slot.item_data as WeaponItemData
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 40) 
		button.text = "%s   %s/%s" % [
			weapon.name,
			weapon.durability,
			weapon.max_durability
		]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Show forecast when hovered
		button.mouse_entered.connect(func():
			var forecast := CombatCalculator.get_combat_forecast(unit, null, weapon)
			forecast_label.text = "ATK: %02d    HIT: %02d    CRIT: %02d" % [
				int(forecast.attack),
				int(forecast.hit),
				int(forecast.crit)]
				

		)

		# Handle weapon selection
		button.pressed.connect(func():
			unit.equip_item(weapon)

			unit.attack_range = weapon.atk_range
			game_board._unit_overlay.clear_attackable_cells()
			attackable_cells = game_board.get_attackable_cells(unit)
			game_board._unit_overlay.draw_attackable_cells(attackable_cells)

			game_board.cursor.set_allowed_cells(attackable_cells)
			game_board.cursor.hide()
			game_board.cursor.process_mode = Node.PROCESS_MODE_INHERIT
			game_board.cursor.show_sprite = true
			game_board.cursor.set_pointer_visible(false)
			game_board.cursor.center_on_unit(unit)
			
			game_board._unit_info_panel.visible = false
			game_board.combat_forecast_panel.visible = false
		)

		vbox.add_child(button)
