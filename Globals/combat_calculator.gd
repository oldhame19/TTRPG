extends Node

# =========================
# Combat Forecast Container
# =========================
class CombatForecast:
	var attack: Variant
	var hit: Variant
	var crit: Variant
	var ally_name: Variant
	var enemy_name: Variant
	var ally_weapon: Variant
	var enemy_weapon: Variant
	var ally_hp_current: Variant
	var ally_hp_max: Variant
	var enemy_hp_current: Variant
	var enemy_hp_max: Variant
	var enemy_attack: Variant
	var enemy_hit: Variant
	var enemy_crit: Variant

	func _init(
		attack, hit, crit,
		ally_name, enemy_name,
		ally_weapon, enemy_weapon,
		ally_hp_current, ally_hp_max,
		enemy_hp_current, enemy_hp_max,
		enemy_attack, enemy_hit, enemy_crit
	):
		self.attack = attack
		self.hit = hit
		self.crit = crit
		self.ally_name = ally_name
		self.enemy_name = enemy_name
		self.ally_weapon = ally_weapon
		self.enemy_weapon = enemy_weapon
		self.ally_hp_current = ally_hp_current
		self.ally_hp_max = ally_hp_max
		self.enemy_hp_current = enemy_hp_current
		self.enemy_hp_max = enemy_hp_max
		self.enemy_attack = enemy_attack
		self.enemy_hit = enemy_hit
		self.enemy_crit = enemy_crit


# =========================
# Stat Calculations
# =========================
static func calculate_stats(ally: Unit, enemy: Unit, temp_weapon: WeaponItemData = null) -> Dictionary:
	if ally == null or ally.current_stats == null:
		return {"attack": "--", "hit": "--", "crit": "--"}

	var weapon := temp_weapon if temp_weapon != null else ally.equipped_weapon as WeaponItemData
	var raw_stats := ally.get_raw_stats()
	var str := raw_stats.strength
	var dex := raw_stats.dexterity
	var faith := raw_stats.faith

	var attack := 0
	var hit := 0
	var crit := 0
	var effectiveness := 1

	# ========== ATTACK ==========
	if weapon != null:
		if weapon.effective_against != WeaponItemData.Effectiveness.NONE and enemy != null and enemy.current_class != null:
			if weapon.Effectiveness == enemy.current_class.ClassType:
				effectiveness = 2
		attack = str + int(weapon.power * effectiveness)
	else:
		attack = str

	# ========== HIT ==========
	var distance_penalty := 0
	if weapon != null and enemy != null:
		var ally_pos: Vector2i = ally.grid.calculate_grid_coordinates(ally.position)
		var enemy_pos: Vector2i = enemy.grid.calculate_grid_coordinates(enemy.position)
		var manhattan_distance: int = abs(ally_pos.x - enemy_pos.x) + abs(ally_pos.y - enemy_pos.y)
		if manhattan_distance > 1:
			distance_penalty = weapon.distance_hit_penalty
		hit = weapon.hit_chance + ((dex * 2) + int(faith / 2)) - distance_penalty
	else:
		hit = (dex * 2) + int(faith / 2)

	# ========== CRIT ==========
	if weapon != null:
		crit = weapon.crit_chance + int((dex + faith) / 2)
	else:
		crit = int((dex + faith) / 2)

	return {
		"attack": str(attack),
		"hit": str(hit),
		"crit": str(crit)
	}


# =========================
# Combat Forecast Generation
# =========================
static func get_combat_forecast(
	ally: Unit,
	enemy: Unit,
	override_weapon: WeaponItemData = null
) -> CombatForecast:

	var ally_name = "--"
	var enemy_name = "--"
	var ally_weapon_ref = "--"
	var enemy_weapon_ref = "--"
	var ally_hp_current = "--"
	var ally_hp_max = "--"
	var enemy_hp_current = "--"
	var enemy_hp_max = "--"
	var ally_attack = "--"
	var ally_hit = "--"
	var ally_crit = "--"
	var enemy_attack = "--"
	var enemy_hit = "--"
	var enemy_crit = "--"

	# ========== ALLY ==========
	if ally != null and ally.unit_data != null:
		ally_name = ally.unit_data.unit_name
		ally_weapon_ref = override_weapon if override_weapon != null else ally.equipped_weapon
		ally_hp_current = ally.hp
		ally_hp_max = ally.current_stats.max_hp if ally.current_stats != null else "--"

		if ally.current_stats != null:
			var ally_stats = calculate_stats(ally, enemy, override_weapon)
			ally_attack = ally_stats["attack"]
			ally_hit = ally_stats["hit"]
			ally_crit = ally_stats["crit"]

	# ========== ENEMY ==========
	if enemy != null and enemy.unit_data != null:
		enemy_name = enemy.unit_data.unit_name
		enemy_weapon_ref = enemy.equipped_weapon
		enemy_hp_current = enemy.hp
		enemy_hp_max = enemy.current_stats.max_hp if enemy.current_stats != null else "--"

		if enemy.current_stats != null:
			var enemy_stats = calculate_stats(enemy, ally)
			enemy_attack = enemy_stats["attack"]
			enemy_hit = enemy_stats["hit"]
			enemy_crit = enemy_stats["crit"]

	return CombatForecast.new(
		ally_attack,
		ally_hit,
		ally_crit,
		ally_name,
		enemy_name,
		ally_weapon_ref,
		enemy_weapon_ref,
		ally_hp_current,
		ally_hp_max,
		enemy_hp_current,
		enemy_hp_max,
		enemy_attack,
		enemy_hit,
		enemy_crit
	)
