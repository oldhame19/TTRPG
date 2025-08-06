#combat_forecast_panel.gd
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
	ally_weapon_label.text = forecast.ally_weapon
	ally_hp_label.text = "%s/%s" % [str(forecast.ally_hp_current), str(forecast.ally_hp_max)]
	ally_atk_label.text = str(forecast.attack)  # changed from damage
	ally_hit_label.text = str(forecast.hit)
	ally_crit_label.text = str(forecast.crit)

	# Enemy side
	enemy_name_label.text = forecast.enemy_name
	enemy_weapon_label.text = forecast.enemy_weapon
	enemy_hp_label.text = "%s/%s" % [str(forecast.enemy_hp_current), str(forecast.enemy_hp_max)]
	enemy_atk_label.text = str(forecast.enemy_attack)  # changed from enemy_damage
	enemy_hit_label.text = str(forecast.enemy_hit)
	enemy_crit_label.text = str(forecast.enemy_crit)
