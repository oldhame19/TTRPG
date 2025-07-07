extends CanvasLayer
@onready var cursor: Cursor = get_parent()._cursor

func _ready() -> void:
	$VBoxContainer/UnitsButton.grab_focus()
	#disable cursor
	cursor.hide()
	cursor.process_mode = Node.PROCESS_MODE_DISABLED

func _on_units_button_pressed() -> void:
	pass



func _on_options_button_pressed() -> void:
	pass # Replace with function body.



func _on_end_turn_button_pressed() -> void:
	pass # Replace with function body.



func _on_close_button_pressed() -> void:
	#enable cursor and close menu
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.reset_cursor()
	cursor.show()
	queue_free()
