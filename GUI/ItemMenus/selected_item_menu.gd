extends Control  # Or PopupPanel, etc.

var slot: SlotData
var unit: Unit
var source: String  # "inventory" or "held_items"

func _ready():
	$VBoxContainer/EquipButton.pressed.connect(_on_equip_button_pressed)
	$VBoxContainer/HoldButton.pressed.connect(_on_hold_button_pressed)
	$VBoxContainer/TradeButton.pressed.connect(_on_trade_button_pressed)
	$VBoxContainer/StoreButton.pressed.connect(_on_store_button_pressed)
	$VBoxContainer/CloseButton.pressed.connect(_on_close_button_pressed)
	$VBoxContainer/UseButton.pressed.connect(_on_use_button_pressed)

	# Conditional visibility
	$VBoxContainer/HoldButton.visible = (source == "inventory")
	$VBoxContainer/StoreButton.visible = (source == "held_items")

	# Only show Equip if it's an equippable item
	if slot.item_data.category != ItemData.Category.Equipment:
		$VBoxContainer/EquipButton.visible = false

	# Only show Use button if the item is consumable
	$VBoxContainer/UseButton.visible = slot.item_data.is_consumable()

func _on_close_button_pressed() -> void:
	# deselects the item
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
	pass # Replace with function body.
