extends CanvasLayer
class_name LevelUpScreen

signal finished

@onready var stat_panel: GridContainer = $StatPanel/GridContainer
@onready var unit_name_label: Label = $UnitPanel/UnitNameLabel
@onready var unit_class_label: Label = $UnitPanel/HBoxContainer/UnitClassLabel
@onready var unit_level_label: Label = $UnitPanel/HBoxContainer/UnitLevelLabel

var unit: Unit = null
var previous_stats: StatBlock = null

var labels: Dictionary

func _ready():
	labels = {
		"hp": stat_panel.get_node("hp"),
		"str": stat_panel.get_node("str"),
		"def": stat_panel.get_node("def"),
		"spd": stat_panel.get_node("spd"),
		"dex": stat_panel.get_node("dex"),
		"cha": stat_panel.get_node("cha"),
		"fth": stat_panel.get_node("fth"),
		"totals": stat_panel.get_node("totals"),
	}

func show_level_up(unit_to_display: Unit) -> void:
	unit = unit_to_display
	if unit == null:
		return
	
	
	
	unit_name_label.text = unit.unit_data.unit_name if unit.unit_data else "Unknown"
	unit_class_label.text = unit.current_class.name if unit.current_class else "Unknown Class"
	
	# Level label only shows arrow if level increased
	var prev_level = unit.level - 1
	if unit.level > prev_level:
		unit_level_label.text = str(prev_level) + " -> " + str(unit.level)
	else:
		unit_level_label.text = str(unit.level)
	
	_update_stat_labels()
	visible = true
	emit_signal("finished")

func _update_stat_labels() -> void:
	if unit == null or previous_stats == null:
		return
	
	var current = unit.get_raw_stats()
	var stat_order = [
		["hp", "max_hp"], ["str", "strength"], ["def", "defense"],
		["spd", "speed"], ["dex", "dexterity"], ["cha", "charisma"], ["fth", "faith"]
	]

	var total_prev = 0
	var total_curr = 0
	
	for pair in stat_order:
		var label_name = pair[0]
		var stat_key = pair[1]
		var label: Label = labels.get(label_name)
		if label == null:
			continue
		
		var prev_val = previous_stats.get(stat_key)
		var curr_val = current.get(stat_key)
		
		# Show "old +increase -> new" if stat increased
		if curr_val > prev_val:
			var increase = curr_val - prev_val
			label.text = str(prev_val) + " +" + str(increase) + " -> " + str(curr_val)
		else:
			label.text = str(prev_val)
		
		# Accumulate totals (including HP)
		total_prev += prev_val
		total_curr += curr_val
	
	# Set totals label with arrow and increase if changed
	var totals_label: Label = labels.get("totals")
	if totals_label:
		if total_curr > total_prev:
			var total_increase = total_curr - total_prev
			totals_label.text = str(total_prev) + " +" + str(total_increase) + " -> " + str(total_curr)
		else:
			totals_label.text = str(total_prev)


func hide_screen() -> void:
	visible = false
	unit = null
	previous_stats = null

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton and event.pressed:
		hide_screen()
