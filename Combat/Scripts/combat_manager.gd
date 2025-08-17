extends CanvasLayer
class_name CombatManager

signal combat_finished(attacker, defender, result) 
# result can be a dictionary or enum for win/loss/draw if needed

# To be assigned externally before starting combat
var attacker: Unit
var defender: Unit

# Reference to the combat_calculator singleton or autoload
#@onready var combat_calc = preload("res://Globals/combat_calculator.gd")

func start_combat(attacking_unit: Unit, defending_unit: Unit) -> void:
	attacker = attacking_unit
	defender = defending_unit
	
	attacker.has_acted = true
	attacker.update_acted_visual()
	# Disable input or pause game as needed here

	# Run combat sequence asynchronously (simulate step-by-step)
	# For now just run straight through
	_run_combat()

func _run_combat() -> void:
	if not attacker or not defender:
		print("CombatManager: attacker or defender null")
		return

	# Small delay before starting
	#await get_tree().create_timer(0.05).timeout

	# Step 1: Attacker hits defender
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

	# Step 3: Attacker double attacks if possible
	if _can_double_attack(attacker, defender):
		if !_perform_attack(attacker, defender):
			emit_signal("combat_finished", attacker, defender, {"status": "finished"})
			return
		await get_tree().process_frame

	# Step 4: Defender double attacks if possible and can retaliate
	if _can_retaliate(defender, attacker) and _can_double_attack(defender, attacker):
		if !_perform_attack(defender, attacker):
			emit_signal("combat_finished", attacker, defender, {"status": "finished"})
			return
		await get_tree().process_frame

	emit_signal("combat_finished", attacker, defender, {"status": "finished"})


func _perform_attack(attacker: Unit, defender: Unit) -> bool:
	var weapon = attacker.equipped_weapon
	if weapon == null:
		print("No weapon equipped for attack")
		return false

	# --- Handle ammo for ranged weapons ---
	if weapon.weapon_type == WeaponItemData.WeaponType.SLING:
		var ammo_slot: SlotData = null
		for slot in attacker.held_items.slots:
			if slot.item_data.name in ["Jagged Stone", "Smooth Stone"] and slot.quantity > 0:
				ammo_slot = slot
				break

		if ammo_slot == null:
			print("⚠ Cannot attack with sling — no stones!")
			return false

		# Consume 1 ammo
		ammo_slot.quantity -= 1
		if ammo_slot.quantity <= 0:
			attacker.held_items.slots.erase(ammo_slot)

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
		print("%s hits %s for %d%s" % [attacker.unit_data.unit_name, defender.unit_data.unit_name, damage, "(CRIT)" if did_crit else ""])

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

	# --- Check for unit death ---
	if defender.hp <= 0:
		_emit_unit_death(defender)
		return false

	return true




func _can_retaliate(defender: Unit, attacker: Unit) -> bool:
	# Check if defender has weapon equipped and can attack attacker based on range
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

	# Make sure positions are grid-aligned
	var atk_pos = attacker.grid.calculate_grid_coordinates(attacker.position)
	var def_pos = defender.grid.calculate_grid_coordinates(defender.position)
	var dist = abs(atk_pos.x - def_pos.x) + abs(atk_pos.y - def_pos.y)

	# Allow attacks within attack_range, including melee (adjacent)
	return dist > 0 and dist <= attacker.attack_range


func _roll_chance(chance: int) -> bool:
	# chance is percentage 0-100
	return randi() % 100 < chance

func _emit_unit_death(unit: Unit) -> void:
	print(unit.unit_data.unit_name, "has died!")
	unit.emit_signal("unit_died", unit)
	# Additional cleanup can be done here (e.g. removing from board)
