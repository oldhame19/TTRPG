extends WeaponItemData
class_name SlingWeapon

enum SlingMode { DEFAULT, JAGGED, SMOOTH }

var mode: SlingMode = SlingMode.DEFAULT

# Keep immutable base stats
@export var base_power: int
@export var base_hit: int
@export var base_crit: int

# Store ammo modifiers per mode
var mode_modifiers := {
	SlingMode.JAGGED: {"power": 6, "hit": 75, "crit": 5},
	SlingMode.SMOOTH: {"power": 3, "hit": 90, "crit": 0},
	SlingMode.DEFAULT: {"power": 0, "hit": 0, "crit": 0},
}

func set_mode(new_mode: SlingMode) -> void:
	mode = new_mode

func get_mode() -> SlingMode:
	return mode

# Computed properties (no stat mutation!)
func get_power() -> int:
	return base_power + mode_modifiers[mode].get("power", 0)

func get_hit_chance() -> int:
	return base_hit + mode_modifiers[mode].get("hit", 0)

func get_crit_chance() -> int:
	return base_crit + mode_modifiers[mode].get("crit", 0)

func get_forecast_with_mode(test_mode: SlingMode) -> Dictionary:
	var mods = mode_modifiers[test_mode]
	return {
		"power": base_power + mods.get("power", 0),
		"hit": base_hit + mods.get("hit", 0),
		"crit": base_crit + mods.get("crit", 0),
	}
