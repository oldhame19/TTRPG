# LevelUpScreen.gd
extends CanvasLayer
class_name LevelUpScreen

@onready var stat_panel: GridContainer = $StatPanel/GridContainer
@onready var unit_name_label: Label = $UnitPanel/UnitNameLabel
@onready var unit_class_label: Label = $UnitPanel/HBoxContainer/UnitClassLabel
@onready var unit_level_label: Label = $UnitPanel/HBoxContainer/UnitLevelLabel

var unit: Unit = null
var previous_stats: StatBlock = null

# Animation speed (seconds per stat increment)
var stat_increment_delay := 0.3

func show_level_up(unit_to_display: Unit) -> void:
	unit = unit_to_display
	if unit == null:
		return
	
	previous_stats = unit.get_raw_stats().duplicate()
	
	unit_name_label.text = unit.unit_data.unit_name if unit.unit_data else "Unknown"
	unit_class_label.text = unit.current_class.name if unit.current_class else "Unknown Class"
	unit_level_label.text = str(unit.level - 1) + " -> " + str(unit.level)
	
	# Reset all stat labels to previous values first
	_reset_stat_labels()
	
	visible = true
	
	# Start the animated update
	await _animate_stats()

func _reset_stat_labels() -> void:
	if unit == null or previous_stats == null:
		return
	
	var current = unit.get_raw_stats()
	for label_node in stat_panel.get_children():
		if label_node is Label:
			var stat_name = _get_stat_name_from_label(label_node.name)
			if stat_name == "Totals":
				label_node.text = ""
			elif stat_name != "":
				label_node.text = str(previous_stats.get(stat_name))

# Removed the ": Callable" return type
func _animate_stats() -> void:
	if unit == null or previous_stats == null:
		return
	
	var current = unit.get_raw_stats()
	var total_prev = 0
	var total_current = 0
	
	# Stat order to animate
	var stat_order = [
		["hp", "max_hp"], 
		["str", "strength"], 
		["def", "defense"], 
		["spd", "speed"], 
		["dex", "dexterity"], 
		["cha", "charisma"], 
		["fth", "faith"]
	]
	
	# Animate each stat
	for pair in stat_order:
		var label_name = pair[0]
		var stat_key = pair[1]
		
		var label = stat_panel.get_node(label_name) if stat_panel.has_node(label_name) else null
		if label == null:
			continue
		
		var prev_val = previous_stats.get(stat_key)
		var curr_val = current.get(stat_key)
		total_prev += prev_val
		total_current += curr_val
		
		if curr_val > prev_val:
			var displayed_val = prev_val
			while displayed_val < curr_val:
				displayed_val += 1
				label.text = str(prev_val) + " -> " + str(displayed_val) + " +" + str(displayed_val - prev_val)
				await get_tree().create_timer(stat_increment_delay).timeout
		else:
			label.text = str(curr_val)
			await get_tree().create_timer(stat_increment_delay).timeout
	
	# Animate totals at the end
	var totals_label = stat_panel.get_node("totals") if stat_panel.has_node("totals") else null
	if totals_label:
		var displayed_total = total_prev
		while displayed_total < total_current:
			displayed_total += 1
			totals_label.text = str(total_prev) + " -> " + str(displayed_total)
			await get_tree().create_timer(stat_increment_delay).timeout
		totals_label.text = str(total_prev) + " -> " + str(total_current)

func _get_stat_name_from_label(label_name: String) -> String:
	var mapping = {
		"hp": "max_hp",
		"str": "strength",
		"def": "defense",
		"spd": "speed",
		"dex": "dexterity",
		"cha": "charisma",
		"fth": "faith",
		"totals": "Totals"
	}
	return mapping.get(label_name, "")

func hide_screen() -> void:
	visible = false
	unit = null
	previous_stats = null
