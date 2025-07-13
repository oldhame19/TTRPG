extends Control  # Or PopupPanel, etc.

var slot: SlotData
var unit: Unit
var source: String  # "inventory" or "held_items"

func _ready():
	# Input monitoring to detect outside clicks
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
