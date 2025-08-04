extends Node

class CombatForecast:
	var damage: Variant
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
	var enemy_damage: Variant
	var enemy_hit: Variant
	var enemy_crit: Variant

	func _init(
		damage, hit, crit,
		attacker_name, defender_name,
		attacker_weapon, defender_weapon,
		attacker_hp_current, attacker_hp_max,
		defender_hp_current, defender_hp_max,
		enemy_damage, enemy_hit, enemy_crit
	):
		self.damage = damage
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
		self.enemy_damage = enemy_damage
		self.enemy_hit = enemy_hit
		self.enemy_crit = enemy_crit
		

static func calculate_stats(attacker: Unit, defender: Unit) -> Dictionary:
	if attacker == null or defender == null:
		return {"damage": "--", "hit": "--", "crit": "--"}

	# Check equipped weapon presence
	var weapon: WeaponItemData = attacker.equipped_weapon
	if weapon == null:
		return {"damage": "--", "hit": "--", "crit": "--"}

	# Make sure stats exist before accessing them
	if attacker.current_stats == null or defender.current_stats == null:
		return {"damage": "--", "hit": "--", "crit": "--"}

	var atk_stat: int = attacker.current_stats.strength
	var def_stat: int = defender.current_stats.defense

	# (rest of the code unchanged)
	var effectiveness_multiplier: int = 1
	if weapon.effective_against != WeaponItemData.Effectiveness.NONE:
		if defender.current_class != null and defender.current_class.class_type == int(weapon.effective_against):
			effectiveness_multiplier = 2

	var bonus_damage: int = 0
	var total_power: int = atk_stat + weapon.power + bonus_damage
	var raw_damage: int = total_power * effectiveness_multiplier - def_stat
	var damage: int = max(0, raw_damage)

	var distance_penalty: int = 0
	var bonus_hit: int = 0
	var hit: int = clamp(weapon.hit_chance + attacker.current_stats.dexterity + bonus_hit - distance_penalty, 0, 100)
	var crit: int = clamp(weapon.crit_chance + int(attacker.current_stats.dexterity / 2), 0, 100)

	return {
		"damage": damage,
		"hit": hit,
		"crit": crit
	}
static func get_combat_forecast(attacker: Unit, defender: Unit) -> CombatForecast:
	# Defaults
	var attacker_name = "--"
	var defender_name = "--"
	var attacker_weapon_name = "--"
	var defender_weapon_name = "--"
	var attacker_hp_current = "--"
	var attacker_hp_max = "--"
	var defender_hp_current = "--"
	var defender_hp_max = "--"
	var ally_damage = "--"
	var ally_hit = "--"
	var ally_crit = "--"
	var enemy_damage = "--"
	var enemy_hit = "--"
	var enemy_crit = "--"

	# Ally side
	if attacker != null and attacker.unit_data != null:
		attacker_name = attacker.unit_data.unit_name
		attacker_weapon_name = attacker.equipped_weapon.name if attacker.equipped_weapon != null else "--"
		attacker_hp_current = attacker.hp
		attacker_hp_max = attacker.current_stats.max_hp if attacker.current_stats != null else "--"
		
		# Only calculate ally stats if weapon and stats exist
		if attacker.equipped_weapon != null and attacker.current_stats != null and defender != null and defender.unit_data != null and defender.current_stats != null:
			var ally_stats = calculate_stats(attacker, defender)
			ally_damage = ally_stats.damage
			ally_hit = ally_stats.hit
			ally_crit = ally_stats.crit

	# Enemy side
	if defender != null and defender.unit_data != null:
		defender_name = defender.unit_data.unit_name
		defender_weapon_name = defender.equipped_weapon.name if defender.equipped_weapon != null else "--"
		defender_hp_current = defender.hp
		defender_hp_max = defender.current_stats.max_hp if defender.current_stats != null else "--"
		
		# Only calculate enemy stats if weapon and stats exist
		if defender.equipped_weapon != null and defender.current_stats != null and attacker != null and attacker.unit_data != null and attacker.current_stats != null:
			var enemy_stats = calculate_stats(defender, attacker)
			enemy_damage = enemy_stats.damage
			enemy_hit = enemy_stats.hit
			enemy_crit = enemy_stats.crit

	return CombatForecast.new(
		ally_damage,
		ally_hit,
		ally_crit,
		attacker_name,
		defender_name,
		attacker_weapon_name,
		defender_weapon_name,
		attacker_hp_current,
		attacker_hp_max,
		defender_hp_current,
		defender_hp_max,
		enemy_damage,
		enemy_hit,
		enemy_crit
	)
