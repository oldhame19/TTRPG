#combat_calculator.gd
extends Node

# =========================
# Combat Forecast Container
# =========================
class CombatForecast:
	var attack: Variant
	var hit: Variant
	var crit: Variant
	var attacker_name: Variant
	var defender_name: Variant
	var attacker_weapon: Variant
	var defender_weapon: Variant
	var attacker_hp_current: Variant
	var attacker_hp_max: Variant
	var defender_hp_current: Variant
	var defender_hp_max: Variant
	var defender_attack: Variant
	var defender_hit: Variant
	var defender_crit: Variant

	func _init(
		attack, hit, crit,
		attacker_name, defender_name,
		attacker_weapon, defender_weapon,
		attacker_hp_current, attacker_hp_max,
		defender_hp_current, defender_hp_max,
		defender_attack, defender_hit, defender_crit
	):
		self.attack = attack
		self.hit = hit
		self.crit = crit
		self.attacker_name = attacker_name
		self.defender_name = defender_name
		self.attacker_weapon = attacker_weapon
		self.defender_weapon = defender_weapon
		self.attacker_hp_current = attacker_hp_current
		self.attacker_hp_max = attacker_hp_max
		self.defender_hp_current = defender_hp_current
		self.defender_hp_max = defender_hp_max
		self.defender_attack = defender_attack
		self.defender_hit = defender_hit
		self.defender_crit = defender_crit


# =========================
# Forecast Stat Calculations (Atk, Hit, Crit)
# =========================
static func calculate_forecast_stats(attacker: Unit, defender: Unit, temp_weapon: WeaponItemData = null) -> Dictionary:
	if attacker == null or attacker.current_stats == null:
		return {"attack": "--", "hit": "--", "crit": "--"}

	var weapon := temp_weapon if temp_weapon != null else attacker.equipped_weapon as WeaponItemData
	var stats := attacker.get_stats_with_abilities()
	var str := stats.strength
	var dex := stats.dexterity
	var faith := stats.faith

	var bonuses: Dictionary = attacker.get_combat_stat_bonuses()
	var hit_bonus: int = bonuses.get("hit", 0)
	var crit_bonus: int = bonuses.get("crit", 0)

	var attack := 0
	var hit := 0
	var crit := 0
	var effectiveness := 1

	# ========== ATTACK ==========
	if weapon != null:
		if weapon.effective_against != WeaponItemData.Effectiveness.NONE and defender != null and defender.current_class != null:
			if weapon.effective_against == defender.current_class.class_type:
				effectiveness = 2
		attack = str + int(weapon.power * effectiveness)
	else:
		attack = str

	# ========== HIT ==========
	var distance_penalty := 0
	if weapon != null and defender != null:
		var attacker_pos: Vector2i = attacker.grid.calculate_grid_coordinates(attacker.position)
		var defender_pos: Vector2i = defender.grid.calculate_grid_coordinates(defender.position)
		var manhattan_distance: int = abs(attacker_pos.x - defender_pos.x) + abs(attacker_pos.y - defender_pos.y)
		if manhattan_distance > 1:
			distance_penalty = weapon.distance_hit_penalty
		hit = weapon.hit_chance + int((dex + faith) / 2) - distance_penalty + hit_bonus
	else:
		hit = (dex * 2) + int(faith / 2) + hit_bonus

	# ========== CRIT ==========
	if weapon != null:
		crit = weapon.crit_chance + int((dex + faith) / 2) + crit_bonus
	else:
		crit = int((dex + faith) / 2) + crit_bonus

	return {
		"attack": str(attack),
		"hit": str(hit),
		"crit": str(crit)
	}


# =========================
# Combat Forecast Generation (Preview of Atk, Hit, Crit (not actual damage))
# =========================
static func get_combat_forecast(attacker: Unit, defender: Unit, override_weapon: WeaponItemData = null) -> CombatForecast:

	var attacker_name = "--"
	var defender_name = "--"
	var attacker_weapon_ref = "--"
	var defender_weapon_ref = "--"
	var attacker_hp_current = "--"
	var attacker_hp_max = "--"
	var defender_hp_current = "--"
	var defender_hp_max = "--"
	var attacker_attack = "--"
	var attacker_hit = "--"
	var attacker_crit = "--"
	var defender_attack = "--"
	var defender_hit = "--"
	var defender_crit = "--"

	# ========== ATTACKER ==========
	if attacker != null and attacker.unit_data != null:
		attacker_name = attacker.unit_data.unit_name
		attacker_weapon_ref = override_weapon if override_weapon != null else attacker.equipped_weapon
		attacker_hp_current = attacker.hp
		attacker_hp_max = attacker.current_stats.max_hp if attacker.current_stats != null else "--"

		if attacker.current_stats != null:
			var attacker_stats = calculate_forecast_stats(attacker, defender, override_weapon)
			attacker_attack = attacker_stats["attack"]
			attacker_hit = attacker_stats["hit"]
			attacker_crit = attacker_stats["crit"]

	# ========== DEFENDER ==========
	if defender != null and defender.unit_data != null:
		defender_name = defender.unit_data.unit_name
		defender_weapon_ref = defender.equipped_weapon
		defender_hp_current = defender.hp
		defender_hp_max = defender.current_stats.max_hp if defender.current_stats != null else "--"

		if defender.current_stats != null:
			var defender_stats = calculate_forecast_stats(defender, attacker)
			defender_attack = defender_stats["attack"]
			defender_hit = defender_stats["hit"]
			defender_crit = defender_stats["crit"]

	return CombatForecast.new(
		attacker_attack,
		attacker_hit,
		attacker_crit,
		attacker_name,
		defender_name,
		attacker_weapon_ref,
		defender_weapon_ref,
		attacker_hp_current,
		attacker_hp_max,
		defender_hp_current,
		defender_hp_max,
		defender_attack,
		defender_hit,
		defender_crit
	)



# =========================
# Actual Combat Stat Calculations (for real combat resolution)
# =========================
static func calculate_combat_stats(attacker: Unit, defender: Unit) -> Dictionary:
	if attacker == null or attacker.current_stats == null:
		return {}

	var atk_weapon: WeaponItemData = attacker.equipped_weapon
	var atk_stats: StatBlock = attacker.get_stats_with_abilities()
	var atk_str: int = atk_stats.strength
	var atk_dex: int = atk_stats.dexterity
	var atk_faith: int = atk_stats.faith

	var def_stats: StatBlock = defender.get_stats_with_abilities()
	var def_defense: int = def_stats.defense
	var def_faith: int = def_stats.faith

	# Defense bonus from equipped equipment
	var def_equipment: EquipmentItemData = defender.equipped_armor
	var def_bonus: int = 0
	if def_equipment != null and def_equipment is EquipmentItemData:
		def_bonus = def_equipment.defense_bonus

	# ========== PRT ==========
	var prt: int = def_defense + def_bonus

	# ========== DPA ==========
	var atk_power: int = atk_str
	if atk_weapon != null:
		var effectiveness: int = 1
		if atk_weapon.effective_against != WeaponItemData.Effectiveness.NONE and defender.current_class != null:
			if int(atk_weapon.effective_against) == int(defender.current_class.class_type):
				effectiveness = 2
		atk_power += int(atk_weapon.power * effectiveness)

	var dpa: int = max(0, atk_power - prt)

	# ========== AS (Attack Speed) ==========
	var atk_weapon_weight: int = atk_weapon.weight if atk_weapon != null else 0
	var atk_equipment_weight: int = attacker.equipped_armor.weight if attacker.equipped_armor != null else 0
	var atk_as: int = max(0, atk_stats.speed - int((atk_weapon_weight + atk_equipment_weight) - (atk_str / 5.0)))

	# ========== Defender AS ==========
	var def_weapon: WeaponItemData = defender.equipped_weapon
	var def_weapon_weight: int = def_weapon.weight if def_weapon != null else 0
	var def_equipment_weight: int = def_equipment.weight if def_equipment != null else 0
	var def_as: int = max(0, def_stats.speed - int((def_weapon_weight + def_equipment_weight) - (def_stats.strength / 5.0)))

	# ========== AH (Actual Hit) ==========
	var forecast: Dictionary = calculate_forecast_stats(attacker, defender)
	var raw_hit: int = int(forecast["hit"]) if typeof(forecast["hit"]) == TYPE_STRING else forecast["hit"]
	var def_avo: int = def_as
	var ah: int = max(0, raw_hit - def_avo)

	# ========== AC (Actual Crit) ==========
	var raw_crit: int = int(forecast["crit"]) if typeof(forecast["crit"]) == TYPE_STRING else forecast["crit"]
	var def_crit_avo: int = def_faith
	var ac: int = max(0, raw_crit - def_crit_avo)

	# ========== Double Attack ==========
	var double_attack: bool = atk_as >= def_as + 4

	return {
		"prt": prt,
		"dpa": dpa,
		"as": atk_as,
		"avo": def_as,
		"crit_avo": def_crit_avo,
		"ah": ah,
		"ac": ac,
		"double": double_attack
	}

static func calculate_full_combat_stats(attacker: Unit, defender: Unit) -> Dictionary:
	return {
		"attacker": calculate_combat_stats(attacker, defender),
		"defender": calculate_combat_stats(defender, attacker)
	}
