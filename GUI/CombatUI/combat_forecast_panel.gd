extends CanvasLayer
class_name CombatForecastPanel

@onready var attacker_name_label = $CombatForecastPanel/MarginContainer/GridContainer/AttackerName
@onready var attacker_weapon_label = $CombatForecastPanel/MarginContainer/GridContainer/AttackerWPN
@onready var attacker_hp_label = $CombatForecastPanel/MarginContainer/GridContainer/AttackerHP
@onready var attacker_atk_label = $CombatForecastPanel/MarginContainer/GridContainer/AttackerATK
@onready var attacker_hit_label = $CombatForecastPanel/MarginContainer/GridContainer/AttackerHIT
@onready var attacker_crit_label = $CombatForecastPanel/MarginContainer/GridContainer/AttackerCRIT

@onready var defender_name_label = $CombatForecastPanel/MarginContainer/GridContainer/DefenderName
@onready var defender_weapon_label = $CombatForecastPanel/MarginContainer/GridContainer/DefenderWPN
@onready var defender_hp_label = $CombatForecastPanel/MarginContainer/GridContainer/DefenderHP
@onready var defender_atk_label = $CombatForecastPanel/MarginContainer/GridContainer/DefenderATK
@onready var defender_hit_label = $CombatForecastPanel/MarginContainer/GridContainer/DefenderHIT
@onready var defender_crit_label = $CombatForecastPanel/MarginContainer/GridContainer/DefenderCRIT

func update_forecast(forecast: CombatCalculator.CombatForecast, combat_stats: Dictionary) -> void:
	# Attacker side
	attacker_name_label.text = forecast.attacker_name
	if forecast.attacker_weapon is WeaponItemData:
		attacker_weapon_label.text = "%s   %d" % [
			forecast.attacker_weapon.name,
			forecast.attacker_weapon.durability,
		]
	else:
		attacker_weapon_label.text = "--"

	attacker_hp_label.text = "%s/%s" % [str(forecast.attacker_hp_current), str(forecast.attacker_hp_max)]

	# Use dpa for attack, ah for hit, ac for crit
	if combat_stats.has("attacker"):
		var atk_stats = combat_stats["attacker"]
		attacker_atk_label.text = str(atk_stats.get("dpa", "--"))
		attacker_hit_label.text = str(atk_stats.get("ah", "--"))
		attacker_crit_label.text = str(atk_stats.get("ac", "--"))
	else:
		attacker_atk_label.text = str(forecast.attack)
		attacker_hit_label.text = str(forecast.hit)
		attacker_crit_label.text = str(forecast.crit)

	# Defender side
	defender_name_label.text = forecast.defender_name
	if forecast.defender_weapon is WeaponItemData:
		defender_weapon_label.text = "%s   %d" % [
			forecast.defender_weapon.name,
			forecast.defender_weapon.durability,
		]
	else:
		defender_weapon_label.text = "--"

	defender_hp_label.text = "%s/%s" % [str(forecast.defender_hp_current), str(forecast.defender_hp_max)]

	# Use dpa for attack, ah for hit, ac for crit for defender as well
	if combat_stats.has("defender"):
		var def_stats = combat_stats["defender"]
		defender_atk_label.text = str(def_stats.get("dpa", "--"))
		defender_hit_label.text = str(def_stats.get("ah", "--"))
		defender_crit_label.text = str(def_stats.get("ac", "--"))
	else:
		defender_atk_label.text = str(forecast.defender_attack)
		defender_hit_label.text = str(forecast.defender_hit)
		defender_crit_label.text = str(forecast.defender_crit)
