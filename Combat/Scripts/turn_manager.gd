extends Node
class_name TurnManager

@onready var game_board: GameBoard
@onready var combat_manager: CombatManager

signal phase_started(phase_name: String)
signal phase_ended(phase_name: String)
signal battle_ended(winner: String)

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var phases: Array[String] = ["player", "enemy"]
var current_phase_index: int = 0
var _phase_ending: bool = false

var unit_groups := {
	"player": [], # Array[Unit]
	"enemy": []   # Array[Unit]
}

func _ready() -> void:
	call_deferred("start_phase", phases[current_phase_index])

# ================= Phase Control =================

func start_phase(phase_name: String) -> void:
	emit_signal("phase_started", phase_name)
	print("Starting phase:", phase_name)

	if phase_name == "player":
		for group_name in ["player", "enemy"]:
			for u in unit_groups.get(group_name, []):
				if is_instance_valid(u) and not u.is_dead:
					u.reset_turn()
	else:
		# Wait for phase animation to finish before starting AI
		await game_board.phase_transition_finished
		var raw_units: Array = unit_groups.get("enemy", [])
		var units: Array[Unit] = []
		for u in raw_units:
			if is_instance_valid(u) and not u.is_dead:
				units.append(u)

		if units.size() == 0:
			call_deferred("end_phase")
			return

		await _run_ai_phase(units)



func end_phase() -> void:
	if _phase_ending:
		print("Ignoring repeated end_phase call")
		return
	_phase_ending = true

	print("end_phase called, current phase:", phases[current_phase_index])
	emit_signal("phase_ended", phases[current_phase_index])

	if _check_battle_end():
		_phase_ending = false
		return

	current_phase_index = (current_phase_index + 1) % phases.size()
	print("Switched to phase index:", current_phase_index)
	call_deferred("start_phase", phases[current_phase_index])
	_phase_ending = false

func unit_finished_turn(unit: Unit) -> void:
	unit.has_acted = true
	unit.update_acted_visual()

	var current_phase: String = phases[current_phase_index]
	var remaining: Array[Unit] = []
	for u in unit_groups.get(current_phase, []):
		if is_instance_valid(u) and not u.is_dead and not u.has_acted:
			remaining.append(u)

	if remaining.size() == 0 and not _phase_ending:
		call_deferred("end_phase")

func _check_battle_end() -> bool:
	var alive_players := []
	for u in unit_groups["player"]:
		if is_instance_valid(u) and not u.is_dead:
			alive_players.append(u)
	if alive_players.size() == 0:
		emit_signal("battle_ended", "enemy")
		return true

	var alive_enemies := []
	for u in unit_groups["enemy"]:
		if is_instance_valid(u) and not u.is_dead:
			alive_enemies.append(u)
	if alive_enemies.size() == 0:
		emit_signal("battle_ended", "player")
		return true

	return false

# ================= AI Phase =================

func _run_ai_phase(units: Array[Unit]) -> void:
	var planned_enemy_cells: Array = [] # Track AI moves for team awareness
	for u in units:
		if not is_instance_valid(u) or u.is_dead:
			continue

		# Boss-specific behavior
		if u.is_boss:
			# Find any player unit in attack range from current position
			var player_in_range: Unit = null
			for p in unit_groups["player"]:
				if is_instance_valid(p) and not p.is_dead:
					var dist = abs(u.cell.x - p.cell.x) + abs(u.cell.y - p.cell.y)
					if dist <= u.attack_range:
						player_in_range = p
						break

			if player_in_range:
				# Attack without moving
				await get_tree().create_timer(0.3).timeout
				await _combat_attack(u, player_in_range)
				u.has_acted = true
				unit_finished_turn(u)
			else:
				# Check if any player can be reached and attacked if we move
				var possible_moves = game_board._dijkstra(u.cell, u.move_range, false)
				var found_action := false
				for move_cell in possible_moves:
					for p in unit_groups["player"]:
						if is_instance_valid(p) and not p.is_dead:
							var dist = abs(move_cell.x - p.cell.x) + abs(move_cell.y - p.cell.y)
							if dist <= u.attack_range:
								# Move and attack this target
								await get_tree().create_timer(0.3).timeout
								var path = _find_path_to_cell(possible_moves, move_cell, u.cell)
								game_board._units.erase(u.cell)
								u.cell = move_cell
								game_board._units[u.cell] = u
								u.walk_along(path)
								await u.walk_finished
								await _combat_attack(u, p)
								u.has_acted = true
								unit_finished_turn(u)
								found_action = true
								break
					if found_action:
						break
				if not found_action:
					# Boss does nothing this turn
					u.has_acted = true
					unit_finished_turn(u)
			continue # Skip normal AI evaluation for bosses

		# ===== Normal AI behavior for non-boss enemies =====
		await get_tree().create_timer(0.3).timeout
		var best_action: Dictionary = _evaluate_best_action(u, 2, planned_enemy_cells)
		if best_action != {} and !u.has_acted:
			await _execute_ai_action(u, best_action)
			u.has_acted = true
			planned_enemy_cells.append(best_action.move_to)

# ================= AI Actions =================

func _execute_ai_action(unit: Unit, action: Dictionary) -> void:
	if action.has("move_to") and action.move_to != unit.cell:
		var reachable: = game_board._dijkstra(unit.cell, unit.move_range, false)
		var path: = _find_path_to_cell(reachable, action.move_to, unit.cell)

		if path.size() > 0:
			game_board._units.erase(unit.cell)
			unit.cell = action.move_to
			game_board._units[unit.cell] = unit
			unit.walk_along(path)
			await unit.walk_finished  # still valid in Godot 4.4

	if action.has("attack_target") and action.attack_target != null:
		await _combat_attack(unit, action.attack_target)

	unit_finished_turn(unit)

func _find_path_to_cell(reachable_cells: Array, target: Vector2, start: Vector2) -> Array[Vector2]:
	var path: Array[Vector2] = []
	var current: Vector2 = target
	var safety_counter: int = 0
	const MAX_ITER: int = 100

	while current != start and safety_counter < MAX_ITER:
		safety_counter += 1
		path.insert(0, current)

		var next_cell: Vector2 = Vector2(-1, -1)
		var min_dist: float = 9999.0
		for dir in DIRECTIONS:
			var neighbor: Vector2 = current - dir
			if reachable_cells.has(neighbor):
				var dist: float = (neighbor - start).length()
				if dist < min_dist:
					min_dist = dist
					next_cell = neighbor

		if next_cell == Vector2(-1, -1):
			print("⚠ Could not find next cell from", current)
			break

		current = next_cell

	if path.size() == 0 or path[0] != start:
		path.insert(0, start)

	return path

# ================= Combat =================

# Member variable
# Member variable
var _combat_finished_flag := false

# Method to handle combat finished
func _on_combat_finished(attacker: Unit, defender: Unit, result: Dictionary) -> void:
	_combat_finished_flag = true

# Combat attack function
func _combat_attack(attacker: Unit, defender: Unit) -> void:
	if combat_manager == null:
		print("⚠ CombatManager not assigned!")
		return

	_combat_finished_flag = false

	# Connect using a Callable (Godot 4.x style)
	combat_manager.connect("combat_finished", Callable(self, "_on_combat_finished"), CONNECT_ONE_SHOT)

	combat_manager.start_combat(attacker, defender)

	# Wait for combat to finish
	while not _combat_finished_flag:
		await get_tree().process_frame



# ================= AI Evaluation =================

func _evaluate_best_action(unit: Unit, depth: int, blocked_cells: Array = []) -> Dictionary:
	var raw_players = unit_groups["player"]
	var player_units: Array[Unit] = []
	for u in raw_players:
		if is_instance_valid(u) and not u.is_dead:
			player_units.append(u)

	if player_units.size() == 0:
		return {"reward": -99999.0, "move_to": unit.cell, "attack_target": null}

	var possible_moves = game_board._dijkstra(unit.cell, unit.move_range, false)
	possible_moves = possible_moves.filter(func(c): return not blocked_cells.has(c))

	var best: Dictionary = {"reward": -99999.0, "move_to": unit.cell, "attack_target": null}

	for move_cell in possible_moves:
		# Determine attackable units from this move cell
		var targets: Array[Unit] = []
		for p in player_units:
			var dist = abs(move_cell.x - p.cell.x) + abs(move_cell.y - p.cell.y)
			if dist <= unit.attack_range:
				targets.append(p)

		if targets.size() > 0:
			for target in targets:
				var reward: float = _simulate_combat_reward(unit, target)
				if depth > 1:
					reward -= _simulate_player_counter_reward(target, depth-1)
				if reward > best.reward:
					best = {"reward": reward, "move_to": move_cell, "attack_target": target}
		else:
			var reward: float = _reward_for_proximity(unit, move_cell, player_units)
			if reward > best.reward:
				best = {"reward": reward, "move_to": move_cell, "attack_target": null}

	return best

func _reward_for_proximity(unit: Unit, cell: Vector2, player_units: Array[Unit]) -> float:
	var min_dist: float = 999.0
	for p in player_units:
		min_dist = min(min_dist, (cell - p.cell).length())
	return 10.0 / (min_dist + 1.0)

func _simulate_player_counter_reward(defender: Unit, depth: int) -> float:
	if defender.current_stats == null:
		return 0.0
	var atk_stats: StatBlock = defender.get_stats_with_abilities()
	var enemy_stats: StatBlock = defender.current_stats
	var expected_damage: float = float(atk_stats.strength - enemy_stats.defense)
	return max(expected_damage, 0.0)

func _simulate_combat_reward(attacker: Unit, defender: Unit) -> float:
	var combat_stats: Dictionary = CombatCalculator.calculate_combat_stats(attacker, defender)
	var damage: float = float(combat_stats.get("dpa", 0))
	if combat_stats.get("double", false):
		damage *= 2.0

	var reward: float = damage * 2.0
	if damage >= float(defender.hp):
		reward += 100.0  # Extra reward for potential kill

	var counter_stats: Dictionary = CombatCalculator.calculate_combat_stats(defender, attacker)
	var counter_damage: float = float(counter_stats.get("dpa", 0))
	if counter_stats.get("double", false):
		counter_damage *= 2.0
	reward -= counter_damage * 1.5  # Penalize for retaliation

	if attacker.attack_range > 1:
		reward += 5.0  # Slight bonus for ranged attacks

	return reward
