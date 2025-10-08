extends CanvasLayer
class_name CombatManager

signal combat_finished(attacker, defender, result)

var attacker: Unit
var defender: Unit

func start_combat(attacking_unit: Unit, defending_unit: Unit) -> void:
	attacker = attacking_unit
	defender = defending_unit

	attacker.has_acted = true
	attacker.update_acted_visual()
	_run_combat()

func _run_combat() -> void:
	if not attacker or not defender:
		print("CombatManager: attacker or defender null")
		return

	# Step 1: Attacker attacks
	if !_perform_attack(attacker, defender):
		emit_signal("combat_finished", attacker, defender, {"status": "finished"})
		return
	await get_tree().process_frame

	# Step 2: Defender retaliates if possible
	if _can_retaliate(defender, attacker):
		if !_perform_attack(defender, attacker):
			emit_signal("combat_finished", attacker, defender, {"status": "finished"})
			return
		await get_tree().process_frame

	# Step 3: Attacker double attacks
	if _can_double_attack(attacker, defender):
		if !_perform_attack(attacker, defender):
			emit_signal("combat_finished", attacker, defender, {"status": "finished"})
			return
		await get_tree().process_frame

	# Step 4: Defender double attacks if possible
	if _can_retaliate(defender, attacker) and _can_double_attack(defender, attacker):
		if !_perform_attack(defender, attacker):
			emit_signal("combat_finished", attacker, defender, {"status": "finished"})
			return
		await get_tree().process_frame

	emit_signal("combat_finished", attacker, defender, {"status": "finished"})


func _perform_attack(attacker: Unit, defender: Unit) -> bool:
	var weapon = attacker.equipped_weapon
	if weapon == null:
		print("⚠ No weapon equipped for attack")
		return false

	# --- Sling-specific handling ---
	if weapon.weapon_type == WeaponItemData.WeaponType.SLING and weapon is SlingWeapon:
		var sling_weapon: SlingWeapon = weapon
		var mode = sling_weapon.get_mode()

		if mode == SlingWeapon.SlingMode.DEFAULT:
			print("⚠ No ammo mode selected for sling!")
			return false

		# Determine which ammo type corresponds to mode
		var ammo_name := ""
		match mode:
			SlingWeapon.SlingMode.JAGGED:
				ammo_name = "Jagged Stone"
			SlingWeapon.SlingMode.SMOOTH:
				ammo_name = "Smooth Stone"
			_:
				ammo_name = ""

		if ammo_name == "":
			print("⚠ Unknown ammo mode")
			return false

		# Find matching ammo and consume 1 unit
		var ammo_slot: SlotData = null
		for slot in attacker.held_items.slots:
			if slot.item_data and slot.item_data.name == ammo_name and slot.quantity > 0:
				ammo_slot = slot
				break

		if ammo_slot == null:
			print("⚠ Out of %s ammo!" % ammo_name)
			sling_weapon.set_mode(SlingWeapon.SlingMode.DEFAULT)
			return false

		ammo_slot.quantity -= 1
		if ammo_slot.quantity <= 0:
			attacker.held_items.slots.erase(ammo_slot)
			print("💥 %s ammo depleted!" % ammo_name)
			sling_weapon.set_mode(SlingWeapon.SlingMode.DEFAULT)

	# --- Calculate combat stats ---
	var stats = CombatCalculator.calculate_combat_stats(attacker, defender)
	var hit_chance = stats.get("ah", 0)
	var crit_chance = stats.get("ac", 0)
	var damage = stats.get("dpa", 0)

	# --- Roll hit / crit ---
	var did_hit = _roll_chance(hit_chance)
	var did_crit = false
	if did_hit:
		did_crit = _roll_chance(crit_chance)
		if did_crit:
			damage *= 3
		defender.take_damage(damage)
		print("%s hits %s for %d%s" % [
			attacker.unit_data.unit_name,
			defender.unit_data.unit_name,
			damage,
			"(CRIT)" if did_crit else ""
		])

		# Grant XP on hit
		var defeated = defender.hp <= 0
		var xp_reward = defender.get_reward_xp(attacker, defeated)
		attacker.gain_xp(xp_reward)
	else:
		print("%s misses %s" % [attacker.unit_data.unit_name, defender.unit_data.unit_name])

	# --- Decrement weapon durability ---
	var broken = weapon.decrement_durability()
	if broken:
		print(weapon.name, "broke!")
		attacker.equipped_weapon = null

	# --- Check for death ---
	if defender.hp <= 0:
		_emit_unit_death(defender)
		return false

	return true


func _can_retaliate(defender: Unit, attacker: Unit) -> bool:
	if defender.equipped_weapon == null:
		return false
	if not _is_in_attack_range(defender, attacker):
		return false
	return true


func _can_double_attack(attacker: Unit, defender: Unit) -> bool:
	var stats = CombatCalculator.calculate_combat_stats(attacker, defender)
	return stats.get("double", false)


func _is_in_attack_range(attacker: Unit, defender: Unit) -> bool:
	if attacker.attack_range <= 0:
		return false

	var atk_pos = attacker.grid.calculate_grid_coordinates(attacker.position)
	var def_pos = defender.grid.calculate_grid_coordinates(defender.position)
	var dist = abs(atk_pos.x - def_pos.x) + abs(atk_pos.y - def_pos.y)

	return dist > 0 and dist <= attacker.attack_range


func _roll_chance(chance: int) -> bool:
	return randi() % 100 < chance


func _emit_unit_death(unit: Unit) -> void:
	print(unit.unit_data.unit_name, "has died!")
	unit.emit_signal("unit_died", unit)
