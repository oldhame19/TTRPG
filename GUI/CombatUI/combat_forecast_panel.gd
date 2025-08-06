extends CanvasLayer
class_name CombatForecastPanel

@onready var ally_name_label = $CombatForecastPanel/MarginContainer/GridContainer/AllyName
@onready var ally_weapon_label = $CombatForecastPanel/MarginContainer/GridContainer/AllyWPN
@onready var ally_hp_label = $CombatForecastPanel/MarginContainer/GridContainer/AllyHP
@onready var ally_atk_label = $CombatForecastPanel/MarginContainer/GridContainer/AllyATK
@onready var ally_hit_label = $CombatForecastPanel/MarginContainer/GridContainer/AllyHIT
@onready var ally_crit_label = $CombatForecastPanel/MarginContainer/GridContainer/AllyCRIT

@onready var enemy_name_label = $CombatForecastPanel/MarginContainer/GridContainer/EnemyName
@onready var enemy_weapon_label = $CombatForecastPanel/MarginContainer/GridContainer/EnemyWPN
@onready var enemy_hp_label = $CombatForecastPanel/MarginContainer/GridContainer/EnemyHP
@onready var enemy_atk_label = $CombatForecastPanel/MarginContainer/GridContainer/EnemyATK
@onready var enemy_hit_label = $CombatForecastPanel/MarginContainer/GridContainer/EnemyHIT
@onready var enemy_crit_label = $CombatForecastPanel/MarginContainer/GridContainer/EnemyCRIT

func update_forecast(forecast: CombatCalculator.CombatForecast) -> void:
	# Ally side
	ally_name_label.text = forecast.ally_name
	if forecast.ally_weapon is WeaponItemData:
		ally_weapon_label.text = "%s   %d/%d" % [
			forecast.ally_weapon.name,
			forecast.ally_weapon.durability,
			forecast.ally_weapon.max_durability
		]
	else:
		ally_weapon_label.text = "--"

	ally_hp_label.text = "%s/%s" % [str(forecast.ally_hp_current), str(forecast.ally_hp_max)]
	ally_atk_label.text = str(forecast.attack)
	ally_hit_label.text = str(forecast.hit)
	ally_crit_label.text = str(forecast.crit)

	# Enemy side
	enemy_name_label.text = forecast.enemy_name
	if forecast.enemy_weapon is WeaponItemData:
		enemy_weapon_label.text = "%s   %d/%d" % [
			forecast.enemy_weapon.name,
			forecast.enemy_weapon.durability,
			forecast.enemy_weapon.max_durability
		]
	else:
		enemy_weapon_label.text = "--"

	enemy_hp_label.text = "%s/%s" % [str(forecast.enemy_hp_current), str(forecast.enemy_hp_max)]
	enemy_atk_label.text = str(forecast.enemy_attack)
	enemy_hit_label.text = str(forecast.enemy_hit)
	enemy_crit_label.text = str(forecast.enemy_crit)
