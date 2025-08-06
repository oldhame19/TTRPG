#unit_info_panel.gd
extends Control
class_name UnitInfoPanel
@onready var panel = $Panel  # ← Add this at the top with your other @onready vars

@onready var name_label = $Panel/VBoxContainer/Panel/NameLabel
@onready var level_label = $Panel/VBoxContainer/GridContainer/LevelLabel
@onready var hp_label = $Panel/VBoxContainer/GridContainer/HPLabel
@onready var equipped_label = $Panel/VBoxContainer/GridContainer/EquippedLabel
@onready var xp_label = $Panel/VBoxContainer/GridContainer/XPLabel

func _ready() -> void:
	panel.custom_minimum_size = Vector2(300, 130)
	# Anchor top-left corner fixed position
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
func update_info(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		visible = false   # <- Hide the panel entirely
		return

	visible = true  # Only show when a valid unit is present

	name_label.text = "%s" % (
		unit.unit_data.unit_name if unit.unit_data != null else "None"
	)
	level_label.text = "Level:       %d" % unit.level
	xp_label.text = "XP:         %02d" % unit.xp


	if unit.current_stats != null:
		hp_label.text = "HP: %d/%d" % [unit.hp, unit.current_stats.max_hp]
	else:
		hp_label.text = "HP: None"

	if unit.equipped_weapon != null:
		equipped_label.text = "%s  [%d/%d]" % [
		unit.equipped_weapon.name,
		unit.equipped_weapon.durability,
		unit.equipped_weapon.max_durability]
	else:
		equipped_label.text = " -- "


#
#func update_info(unit: Unit) -> void:
	#if unit == null or not is_instance_valid(unit):
		#visible = false
		#name_label.text = "Name: None"
		#level_label.text = "Level: None"
		#hp_label.text = "HP: None"
		#equipped_label.text = "Equipped: None"
		#return
#
	#visible = true
#
	#name_label.text = "%s" % (
		#unit.unit_data.unit_name if unit.unit_data != null else "None"
	#)
	#
	#level_label.text = "Level: %d" % unit.level
	#xp_label.text = "XP: %d" % unit.xp 
	#
	#if unit.current_stats != null:
		#hp_label.text = "HP: %d/%d" % [unit.hp, unit.current_stats.max_hp]
	#else:
		#hp_label.text = "HP: None"
#
	#equipped_label.text = "%s" % (
		#unit.equipped_weapon.name if unit.equipped_weapon!= null else "None"
	#)
