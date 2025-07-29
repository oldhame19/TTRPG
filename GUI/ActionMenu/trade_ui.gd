#trade_ui.gd
extends Control
signal trade_closed
signal trade_completed

var unit_a: Unit
var unit_b: Unit
var held_items_menu_a := preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn")
var held_items_menu_b := preload("res://GUI/HeldItems/Scenes/held_item_menu.tscn")
var game_board: GameBoard


@onready var cursor = get_parent().get_node("_cursor")  # assuming cursor is a sibling of this node

var cancel_button: Button = null

func _ready() -> void:
	if cursor:
		cursor.visible = false
		cursor.process_mode = Node.PROCESS_MODE_DISABLED
		cursor.zoom_enabled = false

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
	#menu_a.get_node("Panel").position = Vector2(-400, -250)
#
	#var menu_b = held_items_menu_b.instantiate()
	#menu_b.unit = unit_b
	#menu_b.game_board = get_node("/root/GameBoard")
	#root.add_child(menu_b)
	#menu_b.get_node("Panel").position = Vector2(35, -250)
#
	## Position cancel button below the menus
	#$CancelButton.position = Vector2(700, 700)
#
	## Hide and disable cursor while in trade UI
	#if cursor:
		#cursor.visible = false
		#cursor.process_mode = Node.PROCESS_MODE_DISABLED
		#cursor.zoom_enabled = false
#

#func update_ui() -> void:
	## Clear children except cancel button
	#for child in get_children():
		#if child != $CancelButton:
			#child.queue_free()
#
	## Instantiate and add held item menus as children
	#var menu_a = held_items_menu_a.instantiate()
	#menu_a.unit = unit_a
	#menu_a.game_board = get_node("/root/GameBoard")
	#add_child(menu_a)
	#menu_a.get_node("Panel").position = Vector2(10, 10)  # relative inside popup trade UI
#
	#var menu_b = held_items_menu_b.instantiate()
	#menu_b.unit = unit_b
	#menu_b.game_board = get_node("/root/GameBoard")
	#add_child(menu_b)
	#menu_b.get_node("Panel").position = Vector2(360, 10)
#
### Position cancel button relative to trade UI popup
	#$CancelButton.position = Vector2(180, 520)  # fixed position inside popup
#
	#if cursor:
		#cursor.visible = false
		#cursor.process_mode = Node.PROCESS_MODE_DISABLED
		#cursor.zoom_enabled = false

func update_ui() -> void:
	for child in get_children():
		if child != $CanvasLayer:
			child.queue_free()

	cancel_button = $CanvasLayer/CancelButton

	if cancel_button:
		cancel_button.position = Vector2(535, 535)
		if not cancel_button.is_connected("pressed", Callable(self, "_on_cancel_button_pressed")):
			cancel_button.connect("pressed", Callable(self, "_on_cancel_button_pressed"))
	else:
		push_error("CancelButton is null in update_ui()")

	var menu_a = held_items_menu_a.instantiate()
	menu_a.unit = unit_a
	menu_a.game_board = game_board  
	add_child(menu_a)
	menu_a.get_node("Panel").position = Vector2(-400, -250)
	var close_button_a = menu_a.get_node_or_null("Panel/CloseButton")
	if close_button_a:
		close_button_a.visible = false

	var menu_b = held_items_menu_b.instantiate()
	menu_b.unit = unit_b
	menu_b.game_board = game_board  
	add_child(menu_b)
	menu_b.get_node("Panel").position = Vector2(50, -250)
	var close_button_b = menu_b.get_node_or_null("Panel/CloseButton")
	if close_button_b:
		close_button_b.visible = false
	menu_a.side = "A"
	menu_b.side = "B"
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
	if game_board._unit_info_panel and game_board._active_unit:
		game_board._unit_info_panel.update_info(game_board._active_unit)
		game_board._unit_info_panel.visible = true
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
