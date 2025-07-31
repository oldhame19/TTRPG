extends Control
class_name UnitStatsBox

@onready var stat_grid := $MarginContainer/VBoxContainer/GridContainer
@onready var total_label := $MarginContainer/VBoxContainer/TotalsPanel/TotalLabel

@onready var str_label := stat_grid.get_node("StrengthLabel")
@onready var def_label := stat_grid.get_node("DefenseLabel")
@onready var spd_label := stat_grid.get_node("SpeedLabel")
@onready var dex_label := stat_grid.get_node("DexterityLabel")
@onready var cha_label := stat_grid.get_node("CharismaLabel")
@onready var faith_label := stat_grid.get_node("FaithLabel")

@onready var str := stat_grid.get_node("str")
@onready var def := stat_grid.get_node("def")
@onready var spd := stat_grid.get_node("spd")
@onready var dex := stat_grid.get_node("dex")
@onready var cha := stat_grid.get_node("cha")
@onready var fth := stat_grid.get_node("fth")



func show_unit_stats(stats: StatBlock) -> void:
	if stats == null:
	# Hide stat values and show fallback
		str.text = "-"
		def.text = "-"
		spd.text = "-"
		dex.text = "-"
		cha.text = "-"
		fth.text = "-"
		total_label.text = "Total: None"
		return


	# Set stat values
	str_label.visible = true
	str.visible = true
	str.text = " %d" % stats.strength

	def_label.visible = true
	def.visible = true
	def.text = " %d" % stats.defense

	spd_label.visible = true
	spd.visible = true
	spd.text = " %d" % stats.speed

	dex_label.visible = true
	dex.visible = true
	dex.text = " %d" % stats.dexterity

	cha_label.visible = true
	cha.visible = true
	cha.text = " %d" % stats.charisma

	faith_label.visible = true
	fth.visible = true
	fth.text = " %d" % stats.faith

	# Calculate and display total
	var total := stats.strength + stats.defense + stats.speed + stats.dexterity + stats.charisma + stats.faith
	total_label.text = "Total: %d" % total
