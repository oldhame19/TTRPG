extends WeaponItemData
class_name SlingWeapon

var selected_ammo: String = ""

var ammo_modifiers := {
	"Jagged Stone": {"power": 6, "hit_chance": -10, "crit_chance": 5},
	"Smooth Stone": {"power": 3, "hit_chance": 10, "crit_chance": 0}
}

# Store the original base stats when the weapon is created
var base_power: int
var base_hit_chance: int
var base_crit_chance: int

func _init():
	base_power = power
	base_hit_chance = hit_chance
	base_crit_chance = crit_chance

func set_ammo(ammo_name: String) -> void:
	if ammo_name in ammo_modifiers:
		selected_ammo = ammo_name
		_apply_ammo_stats(ammo_name)
	else:
		selected_ammo = ""
		_reset_to_base_stats()

func _apply_ammo_stats(ammo_name: String) -> void:
	var mods = ammo_modifiers[ammo_name]
	power = base_power + mods.get("power", 0)
	hit_chance = base_hit_chance + mods.get("hit_chance", 0)
	crit_chance = base_crit_chance + mods.get("crit_chance", 0)

func _reset_to_base_stats() -> void:
	power = base_power
	hit_chance = base_hit_chance
	crit_chance = base_crit_chance

func get_selected_ammo() -> String:
	return selected_ammo

func get_forecast_with_ammo(ammo_name: String) -> Dictionary:
	var preview_power = base_power
	var preview_hit = base_hit_chance
	var preview_crit = base_crit_chance

	if ammo_modifiers.has(ammo_name):
		var mods = ammo_modifiers[ammo_name]
		preview_power += mods.get("power")
		preview_hit += mods.get("hit_chance")
		preview_crit += mods.get("crit_chance")

	return {
		"power": preview_power,
		"hit_chance": preview_hit,
		"crit_chance": preview_crit
	}
