extends CanvasLayer
@onready var cursor: Cursor = get_parent()._cursor

func _ready() -> void:
	$VBoxContainer/AttackButton.grab_focus()
	
	cursor.hide()
	cursor.process_mode = Node.PROCESS_MODE_DISABLED

func _on_attack_button_pressed() -> void:
	pass # Replace with function body.


func _on_trade_button_pressed() -> void:
	pass # Replace with function body.


func _on_action_button_pressed() -> void:
	pass # Replace with function body.


func _on_items_button_pressed() -> void:
	var unit = get_parent()._active_unit
	if not unit:
		return

	if unit.is_player:
		# Show the player's full inventory
		var inventory_menu = preload("res://GUI/PlayerInventory/Scenes/player_inventory_menu.tscn").instantiate()
		inventory_menu.unit = unit
		get_tree().get_root().add_child(inventory_menu)
		hide()

		inventory_menu.tree_exited.connect(func(): show())
	else:
		# Show the held items menu for non-player units
		var held_items_menu = preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn").instantiate()
		held_items_menu.unit = unit
		get_tree().get_root().add_child(held_items_menu)
		hide()
		held_items_menu.tree_exited.connect(func(): show())

func _on_wait_button_pressed() -> void:
	#Add:
	#Set curr_unit to wait status
	#Clear active unit
	
	get_parent()._clear_active_unit()
	
	#enable cursor and close menu
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.reset_cursor()
	cursor.show()
	queue_free()

func _on_cancel_button_pressed() -> void:
	#reset the unit's position
	get_parent()._reset_unit()
	
	#enable cursor and close menu
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.reset_cursor()
	cursor.show()
	queue_free()
