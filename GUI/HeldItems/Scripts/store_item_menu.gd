class_name StoreItemMenu

extends Control
var selected_item_menu: Control = null
static var active_store_popup: Control = null

@export var unit: Unit
@export var slot: SlotData
var source_button: Button
static var active_popup: Control = null
var store_button: Button
func _ready():
		# Close any other active popup of the same type
	if active_store_popup and active_store_popup != self:
		active_store_popup.queue_free()
	active_store_popup = self
	# Close any other active popup of the same type
	if active_popup and active_popup != self:
		active_popup.queue_free()
	active_popup = self
	set_process_unhandled_input(true)

	# Connect buttons (if not already connected in the scene)
	$VBoxContainer/StoreOneButton.pressed.connect(_on_store_one_button_pressed)
	$VBoxContainer/StoreAllButton.pressed.connect(_on_store_all_button_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)

func _on_store_one_button_pressed() -> void:
	# Add your store one logic here
	queue_free()

func _on_store_all_button_pressed() -> void:
	# Add your store all logic here
	queue_free()

func _on_back_button_pressed() -> void:
	queue_free()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()

		# If click is outside this menu entirely, close
		if not get_global_rect().has_point(mouse_pos):
			queue_free()
			return

		# Otherwise, check if click was inside any of the 3 buttons, allow if yes
		var clicked_inside_button = false
		for button_name in ["StoreOneButton", "StoreAllButton", "BackButton"]:
			var btn = $VBoxContainer.get_node(button_name)
			if btn and btn.get_global_rect().has_point(mouse_pos):
				clicked_inside_button = true
				break

		# If click was NOT inside any of the buttons, close the menu
		if not clicked_inside_button:
			queue_free()

func _exit_tree():
	if active_popup == self:
		active_popup = null
	if active_store_popup == self:
		active_store_popup = null
