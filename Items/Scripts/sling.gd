# sling.gd
extends WeaponItemData
class_name SlingWeapon

# Track the currently selected ammo type
var selected_ammo: String = ""  # "Jagged Stone" or "Smooth Stone"

# Optional: define stat modifiers per ammo type
var ammo_modifiers := {
	"Jagged Stone": {
		"power": 6,
		"hit_chance": -10,
		"crit_chance": 5
	},
	"Smooth Stone": {
		"power": 3,
		"hit_chance": 10,
		"crit_chance": 0
	}
}

func set_ammo(ammo_name: String) -> void:
	if ammo_name in ammo_modifiers:
		selected_ammo = ammo_name
		_apply_ammo_stats(ammo_name)
	else:
		selected_ammo = ""
		# Optionally reset to default sling stats here
		_apply_default_stats()

func _apply_ammo_stats(ammo_name: String) -> void:
	var mods = ammo_modifiers[ammo_name]
	if mods.has("power"):
		power = mods["power"]
	if mods.has("hit_chance"):
		hit_chance = mods["hit_chance"]
	if mods.has("crit_chance"):
		crit_chance = mods["crit_chance"]

func _apply_default_stats() -> void:
	power = 2
	hit_chance = 75
	crit_chance = 5

func get_selected_ammo() -> String:
	return selected_ammo

# Override decrement_durability to optionally account for ammo
func use_ammo() -> void:
	if selected_ammo == "":
		return
	# Ammo consumption is handled elsewhere (WeaponChoiceMenu or CombatManager)
