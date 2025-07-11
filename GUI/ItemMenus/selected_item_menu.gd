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


func _on_close_button_pressed() -> void:
	# deselects the item
	queue_free()

func _on_store_button_pressed() -> void:
	if source == "held_items":
		print("Store", slot.item_data.name)


func _on_hold_button_pressed() -> void:
	if source == "inventory":
		print("Hold", slot.item_data.name)


func _on_trade_button_pressed() -> void:
	print("Trade placeholder")


func _on_equip_button_pressed() -> void:
	print("Equip", slot.item_data.name)
