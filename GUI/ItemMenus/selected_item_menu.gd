extends Control  # Or PopupPanel, etc.

static var active_popup: Control = null

var slot: SlotData
var unit: Unit
var source: String  # "inventory" or "held_items"
var game_board       # Assigned when creating the popup

func _ready():
	# When opening, if there's already an active popup, close it
	if active_popup and active_popup != self:
		active_popup.queue_free()
	active_popup = self
	set_process_unhandled_input(true)

	$VBoxContainer/EquipButton.pressed.connect(_on_equip_button_pressed)
	$VBoxContainer/HoldButton.pressed.connect(_on_hold_button_pressed)
	$VBoxContainer/TradeButton.pressed.connect(_on_trade_button_pressed)
	$VBoxContainer/StoreButton.pressed.connect(_on_store_button_pressed)
	$VBoxContainer/CloseButton.pressed.connect(_on_close_button_pressed)
	$VBoxContainer/UseButton.pressed.connect(_on_use_button_pressed)
	$VBoxContainer/DescriptionButton.pressed.connect(_on_description_button_pressed)

	$VBoxContainer/HoldButton.visible = (source == "inventory")
	$VBoxContainer/StoreButton.visible = (source == "held_items")

	if slot.item_data.category != ItemData.Category.EQUIPMENT:
		$VBoxContainer/EquipButton.visible = false

	$VBoxContainer/UseButton.visible = slot.item_data.is_consumable()
	if not unit:
		print("SelectedItemMenu: unit is null")
		return
	if not game_board:
		print("SelectedItemMenu: game_board is null")
		return
		

	var unit_cell = unit.grid.calculate_grid_coordinates(unit.position)
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	var trade_visible := false

	if source == "inventory":
		trade_visible = true  # Always visible from inventory
	elif unit and unit.is_player:
		trade_visible = true  # Always visible for player's held items
	elif unit and not unit.is_player and game_board:

		for dir in directions:
			var neighbor_cell = unit_cell + dir
			if game_board._units.has(neighbor_cell):
				var neighbor = game_board._units[neighbor_cell]
				if not neighbor.is_enemy:
					trade_visible = true
					break

	$VBoxContainer/TradeButton.visible = trade_visible

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var global_mouse_pos = get_viewport().get_mouse_position()
		if not get_global_rect().has_point(global_mouse_pos):
			queue_free()

func _on_close_button_pressed() -> void:
	queue_free()

func _on_store_button_pressed() -> void:
	pass

func _on_hold_button_pressed() -> void:
	pass

func _on_trade_button_pressed() -> void:
	pass

func _on_equip_button_pressed() -> void:
	pass

func _on_use_button_pressed() -> void:
	pass

func _on_description_button_pressed() -> void:
	var desc_box_scene = preload("res://GUI/ItemMenus/item_description_box.tscn")
	var desc_box = desc_box_scene.instantiate()
	get_tree().get_root().add_child(desc_box)

	desc_box.show_item_description(slot.item_data)

	if unit and unit.is_player:
		if source == "inventory":
			desc_box.set_position(Vector2(541, 365))
		elif source == "held_items":
			desc_box.set_position(Vector2(350, 365))
		else:
			desc_box.set_position(Vector2(960, 540))
	else:
		desc_box.set_position(Vector2(750, 75))

	desc_box.popup()

func _exit_tree():
	if active_popup == self:
		active_popup = null
