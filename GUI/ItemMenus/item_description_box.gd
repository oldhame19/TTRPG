extends PopupPanel

@onready var stat_grid := $MarginContainer/VBoxContainer/GridContainer
@onready var description_label := $MarginContainer/VBoxContainer/Panel/DescriptionLabel

# Stat value columns
@onready var pwr := stat_grid.get_node("pwr")
@onready var hit := stat_grid.get_node("hit")
@onready var rng := stat_grid.get_node("rng")
@onready var wt := stat_grid.get_node("wt")
@onready var crit := stat_grid.get_node("crit")
@onready var eff := stat_grid.get_node("eff")

# Static label columns
@onready var pwr_label := stat_grid.get_node("PowerLabel")
@onready var hit_label := stat_grid.get_node("HitLabel")
@onready var rng_label := stat_grid.get_node("RangeLabel")
@onready var wt_label := stat_grid.get_node("WeightLabel")
@onready var crit_label := stat_grid.get_node("CritLabel")
@onready var eff_label := stat_grid.get_node("EffectivenessLabel")


func show_item_description(item_data: ItemData) -> void:
	var is_weapon := item_data is WeaponItemData
	var weapon := item_data as WeaponItemData

	# Power
	pwr_label.visible = true
	pwr.visible = true
	if is_weapon and weapon.power > 0:
		pwr.text = " %d" % weapon.power
	else:
		pwr.text = " -"

	# Hit Chance
	hit_label.visible = true
	hit.visible = true
	if is_weapon and weapon.hit_chance > 0:
		hit.text = " %d" % weapon.hit_chance
	else:
		hit.text = " -"

	# Range
	rng_label.visible = true
	rng.visible = true
	if is_weapon and weapon.atk_range > 1:
		rng.text = " %d" % weapon.atk_range
	else:
		rng.text = " -"

	# Weight (this one is still in ItemData)
	wt_label.visible = true
	wt.visible = true
	if item_data.weight > 0:
		wt.text = " %d" % item_data.weight
	else:
		wt.text = " -"

	# Crit Chance
	crit_label.visible = true
	crit.visible = true
	if is_weapon and weapon.crit_chance > 0:
		crit.text = " %d" % weapon.crit_chance
	else:
		crit.text = " -"

	# Effectiveness
	eff_label.visible = true
	eff.visible = true
	if is_weapon and weapon.effective_against != WeaponItemData.Effectiveness.NONE:
		eff.text = " %s" % str(weapon.effective_against)
	else:
		eff.text = " -"

	# Description
	description_label.text = item_data.description
