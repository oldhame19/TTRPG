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
	pass # Replace with function body.



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
