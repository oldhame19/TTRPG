extends CanvasLayer
class_name PauseMenu

@onready var cursor: Cursor = get_parent()._cursor
@onready var turn_manager: TurnManager = get_parent().turn_manager

# Updated paths to labels inside panels
@onready var chapter_label: Label = $HBoxContainer/Panel/ChapterLabel
@onready var turn_label: Label = $HBoxContainer/Panel2/TurnLabel

func _ready() -> void:
	$VBoxContainer/UnitsButton.grab_focus()
	_disable_cursor()

	# Update chapter name from current scene
	var scene_name = get_tree().current_scene.name
	chapter_label.text = scene_name 

	# Update turn number from TurnManager
	if turn_manager:
		turn_label.text = "Turn: " + str(turn_manager.turn_count)
	else:
		turn_label.text = "Turn: - "

# ================= Cursor =================

func _disable_cursor() -> void:
	cursor.hide()
	cursor.process_mode = Node.PROCESS_MODE_DISABLED

func _enable_cursor() -> void:
	cursor.process_mode = Node.PROCESS_MODE_INHERIT
	cursor.reset_cursor()
	cursor.show()

# ================= Button Callbacks =================

func _on_units_button_pressed() -> void:
	pass # Implement unit menu later

func _on_options_button_pressed() -> void:
	pass # Implement options menu later

func _on_end_turn_button_pressed() -> void:
	if turn_manager:
		call_deferred("safe_end_phase")
	_disable_cursor()
	call_deferred("close_menu")

func _on_close_button_pressed() -> void:
	_enable_cursor()
	call_deferred("close_menu")

# ================= Helpers =================

func safe_end_phase() -> void:
	if turn_manager:
		turn_manager.end_phase()

func close_menu() -> void:
	queue_free()
