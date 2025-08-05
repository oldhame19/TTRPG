extends CanvasLayer
class_name WeaponChoiceMenu

@onready var panel := $Panel
@onready var vbox := $Panel/VBoxContainer
@onready var close_button := $Panel/CloseButton
signal close_active_modes
var unit: Unit
var game_board: GameBoard
var attackable_cells := []
var position_on_screen: Vector2 = Vector2(100, 100)  # Default position (can be set before adding to tree)

func _ready():
	close_button.pressed.connect(func():
		close_active_modes.emit()
		game_board._unit_overlay.clear_attackable_cells()
		game_board._unit_info_panel.visible = false
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
		var forecast := CombatCalculator.get_combat_forecast(unit, null, weapon)

		button.text = "%s | ATK: %s HIT: %s CRIT: %s" % [
			weapon.name,
			forecast.attack,
			forecast.hit,
			forecast.crit
		]

		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		button.pressed.connect(func():
			unit.equip_item(weapon)
			
			game_board.combat_forecast_panel.visible = false
			game_board._unit_info_panel.visible = false

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
		)

		vbox.add_child(button)
