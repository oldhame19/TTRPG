#trade_ui.gd
extends Control
signal trade_closed
signal trade_completed

var unit_a: Unit
var unit_b: Unit
var held_items_menu_a := preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn")
var held_items_menu_b := preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn")
@onready var cursor = get_parent().get_node("_cursor")  # assuming cursor is a sibling of this node


func set_units(a: Unit, b: Unit) -> void:
	unit_a = a
	unit_b = b
	update_ui()

#func update_ui() -> void:
	#var root = self
#
	## Clear existing children except the CancelButton
	#for child in root.get_children():
		#if child != $CancelButton:
			#child.queue_free()
#
	## Instantiate held items menus
	#var menu_a = held_items_menu_a.instantiate()
	#menu_a.unit = unit_a
	#menu_a.game_board = get_node("/root/GameBoard")
	#root.add_child(menu_a)
	#menu_a.get_node("Panel").position = Vector2(0, 0)
#
	#var menu_b = held_items_menu_b.instantiate()
	#menu_b.unit = unit_b
	#menu_b.game_board = get_node("/root/GameBoard")
	#root.add_child(menu_b)
	#menu_b.get_node("Panel").position = Vector2(460, 100)
#
	## Position cancel button below the menus
	#$CancelButton.position = Vector2(280, 400)
#
	## Hide and disable cursor while in trade UI
	#if cursor:
		#cursor.visible = false
		#cursor.process_mode = Node.PROCESS_MODE_DISABLED
		#cursor.zoom_enabled = false
func update_ui() -> void:
	var root = self

	# Clear existing children except the CancelButton
	for child in root.get_children():
		if child != $CancelButton:
			child.queue_free()

	# Instantiate held items menus
	var menu_a = held_items_menu_a.instantiate()
	menu_a.unit = unit_a
	menu_a.game_board = get_node("/root/GameBoard")
	root.add_child(menu_a)
	menu_a.get_node("Panel").position = Vector2(-400, -250)

	var menu_b = held_items_menu_b.instantiate()
	menu_b.unit = unit_b
	menu_b.game_board = get_node("/root/GameBoard")
	root.add_child(menu_b)
	menu_b.get_node("Panel").position = Vector2(0, -250)

	# Position cancel button below menu_a's Panel with 10px margin
	var panel_a = menu_a.get_node("Panel")
	var local_pos = menu_a.get_node("Panel").position + Vector2(250, panel_a.get_size().y + 250)
	$CancelButton.position = local_pos





	# Hide and disable cursor while in trade UI
	if cursor:
		cursor.visible = false
		cursor.process_mode = Node.PROCESS_MODE_DISABLED
		cursor.zoom_enabled = false

func _on_trade_completed() -> void:
	emit_signal("trade_completed")

	if cursor:
		cursor.visible = true
		cursor.process_mode = Node.PROCESS_MODE_INHERIT
		cursor.zoom_enabled = true
	queue_free()

func _on_cancel_button_pressed() -> void:
	emit_signal("trade_closed")

	if cursor:
		cursor.visible = true
		cursor.process_mode = Node.PROCESS_MODE_INHERIT
		cursor.zoom_enabled = true
	queue_free()
	

func _unhandled_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			# Consume mouse wheel events to disable zoom during trade UI
			get_viewport().set_input_as_handled()
