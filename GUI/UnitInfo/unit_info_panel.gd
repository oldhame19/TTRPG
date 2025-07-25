extends Control
class_name UnitInfoPanel

@onready var name_label = $Panel/VBoxContainer/NameLabel
@onready var level_label = $Panel/VBoxContainer/LevelLabel
@onready var hp_label = $Panel/VBoxContainer/HPLabel
@onready var equipped_label = $Panel/VBoxContainer/EquippedLabel


func _ready() -> void:
	# Anchor top-left corner fixed position
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0

	# Position the entire panel with offset from top-left
	position = Vector2(16, 16)  # Adjust pixel offset as you want
func update_info(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		visible = false
		name_label.text = "Name: None"
		level_label.text = " Level: None"
		hp_label.text = " HP: None"
		equipped_label.text = " Equipped: None"
		return

	visible = true

	name_label.text = "Name: %s" % (
		unit.unit_data.unit_name if unit.unit_data != null else "None"
	)

	level_label.text = "Level: %d" % unit.level

	if unit.current_stats != null:
		hp_label.text = "HP: %d/%d" % [unit.current_stats.hp, unit.current_stats.max_hp]
	else:
		hp_label.text = "HP: None"

	equipped_label.text = "Equipped: %s" % (
		unit.equipped_item.item_name if unit.equipped_item != null else "None"
	)
