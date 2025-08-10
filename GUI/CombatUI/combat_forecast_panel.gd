extends CanvasLayer
class_name CombatForecastPanel
var attacker_unit: Unit = null
var defender_unit: Unit = null

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

	if combat_stats.has("attacker"):
		var atk_stats = combat_stats["attacker"]
		var atk_text = str(atk_stats.get("dpa", "--"))
		if atk_stats.get("double", false):
			atk_text += " x 2"
		attacker_atk_label.text = atk_text
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

	if combat_stats.has("defender"):
		var def_stats = combat_stats["defender"]

		var can_hit_back := true

		# Attempt to get the units by name — you must implement this function or supply the units in another way
		var defender_unit = defender_unit
		var attacker_unit = attacker_unit

		if forecast.defender_weapon is WeaponItemData and defender_unit != null and attacker_unit != null:
			var defender_pos: Vector2i = defender_unit.grid.calculate_grid_coordinates(defender_unit.position)
			var attacker_pos: Vector2i = attacker_unit.grid.calculate_grid_coordinates(attacker_unit.position)
			var manhattan_distance = abs(defender_pos.x - attacker_pos.x) + abs(defender_pos.y - attacker_pos.y)

			# Get weapon_range as an array safely
			var weapon_range = []
			if defender_unit.equipped_weapon != null:
				var raw_range = defender_unit.equipped_weapon.atk_range
				if typeof(raw_range) == TYPE_INT:
					weapon_range = [raw_range]
				elif typeof(raw_range) == TYPE_ARRAY:
					weapon_range = raw_range

			if manhattan_distance not in weapon_range:
				can_hit_back = false
		else:
			can_hit_back = false

		var def_text = str(def_stats.get("dpa", "--"))
		if def_stats.get("double", false):
			def_text += " x2"

		defender_atk_label.text = def_text

		if can_hit_back:
			defender_hit_label.text = str(def_stats.get("ah", "--"))
			defender_crit_label.text = str(def_stats.get("ac", "--"))
		else:
			defender_hit_label.text = "--"
			defender_crit_label.text = "--"
			defender_atk_label.text = "--"
	else:
		defender_atk_label.text = str(forecast.defender_attack)
		defender_hit_label.text = str(forecast.defender_hit)
		defender_crit_label.text = str(forecast.defender_crit)
