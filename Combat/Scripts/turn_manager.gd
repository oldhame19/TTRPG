#commented code is the base, unmodified from classwork
#extends Node
#class_name TurnManager
#
#@onready var game_board: GameBoard
#@onready var combat_manager: CombatManager
#
#signal phase_started(phase_name: String)
#signal phase_ended(phase_name: String)
#signal battle_ended(winner: String)
#
#const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
#
## ===== Minimax tuning =====
#const AI_MAX_DEPTH := 2
#const AI_MAX_BRANCH := 8
#
#var phases: Array[String] = ["player", "enemy"]
#var current_phase_index: int = 0
#var turn_count: int = 1
#var _phase_ending: bool = false
#
#var unit_groups := {
	#"player": [],
	#"enemy": []
#}
#
#func _ready() -> void:
	#call_deferred("start_phase", phases[current_phase_index])
#
## ================= Phase Control =================
#
#func start_phase(phase_name: String) -> void:
	#emit_signal("phase_started", phase_name)
	#print("Starting phase:", phase_name)
#
	#if phase_name == "player":
		#for group_name in ["player", "enemy"]:
			#for u in unit_groups.get(group_name, []):
				#if is_instance_valid(u) and not u.is_dead:
					#u.reset_turn()
	#else:
		#await game_board.phase_transition_finished
		#var units: Array[Unit] = _alive_units("enemy")
		#if units.is_empty():
			#call_deferred("end_phase")
			#return
		#await _run_ai_phase(units)
#
#func end_phase() -> void:
	#if _phase_ending:
		#return
	#_phase_ending = true
#
	#emit_signal("phase_ended")
#
	#if _check_battle_end():
		#_phase_ending = false
		#return
#
	#current_phase_index = (current_phase_index + 1) % phases.size()
	#if current_phase_index == 0:
		#turn_count += 1
#
	#call_deferred("start_phase", phases[current_phase_index])
	#_phase_ending = false
#
#func unit_finished_turn(unit: Unit) -> void:
	#unit.has_acted = true
	#unit.update_acted_visual()
#
	#var current_phase: String = phases[current_phase_index]
	#for u in unit_groups[current_phase]:
		#if is_instance_valid(u) and not u.is_dead and not u.has_acted:
			#return
#
	#if not _phase_ending:
		#call_deferred("end_phase")
#
#func _check_battle_end() -> bool:
	#if _alive_units("player").is_empty():
		#emit_signal("battle_ended", "enemy")
		#return true
	#if _alive_units("enemy").is_empty():
		#emit_signal("battle_ended", "player")
		#return true
	#return false
#
## ================= AI Phase =================
#
#func _run_ai_phase(units: Array[Unit]) -> void:
	#var planned_enemy_cells := []
#
	#for u in units:
		#if not is_instance_valid(u) or u.is_dead:
			#continue
#
		#await get_tree().create_timer(0.25).timeout
#
		#if u.is_boss:
			#await _run_boss_ai(u)
			#continue
#
		#var best_action := _evaluate_best_action(u, AI_MAX_DEPTH, planned_enemy_cells)
		#if best_action != {}:
			#await _execute_ai_action(u, best_action)
			#planned_enemy_cells.append(best_action.move_to)
#
## ================= Boss AI (unchanged behavior) =================
#
#func _run_boss_ai(u: Unit) -> void:
	#for p in _alive_units("player"):
		#var dist = abs(u.cell.x - p.cell.x) + abs(u.cell.y - p.cell.y)
		#if dist <= u.attack_range:
			#await _combat_attack(u, p)
			#unit_finished_turn(u)
			#return
#
	#var moves = game_board._dijkstra(u.cell, u.move_range, false)
	#for move_cell in moves:
		#for p in _alive_units("player"):
			#var dist = abs(move_cell.x - p.cell.x) + abs(move_cell.y - p.cell.y)
			#if dist <= u.attack_range:
				#var path = _find_path_to_cell(moves, move_cell, u.cell)
				#game_board._units.erase(u.cell)
				#u.cell = move_cell
				#game_board._units[u.cell] = u
				#u.walk_along(path)
				#await u.walk_finished
				#await _combat_attack(u, p)
				#unit_finished_turn(u)
				#return
#
	#unit_finished_turn(u)
#
## ================= Minimax + Alpha Beta =================
#
#func _evaluate_best_action(unit: Unit, depth: int, blocked_cells: Array) -> Dictionary:
	#var actions = _generate_enemy_actions(unit, blocked_cells)
	#if actions.is_empty():
		#return {}
#
	#var best_score := -INF
	#var best_action := {}
	#var alpha := -INF
	#var beta := INF
#
	#for action in actions:
		#var score = _minimax_min_layer(depth - 1, alpha, beta)
		#score += _score_enemy_action(unit, action)
#
		#if score > best_score:
			#best_score = score
			#best_action = action
#
		#alpha = max(alpha, best_score)
		#if beta <= alpha:
			#break
#
	#best_action["reward"] = best_score
	#return best_action
#
#func _minimax_min_layer(depth: int, alpha: float, beta: float) -> float:
	#if depth <= 0:
		#return 0.0
#
	#var best := INF
	#for p in _alive_units("player"):
		#for a in _generate_player_actions(p):
			#var score = _score_player_action(p, a)
#
			#best = min(best, score)
			#beta = min(beta, best)
			#if beta <= alpha:
				#return best
#
	#return best
#
## ================= Action Generation =================
#
#func _generate_enemy_actions(unit: Unit, blocked: Array) -> Array:
	#var actions := []
	#var moves = game_board._dijkstra(unit.cell, unit.move_range, false)
	#moves = moves.filter(func(c): return not blocked.has(c))
	#var players := _alive_units("player")
#
	#for cell in moves:
		#var attacked := false
		#for p in players:
			#if _dist(cell, p.cell) <= unit.attack_range:
				#var a = {"move_to": cell, "attack_target": p}
				#a.score = _simulate_combat_reward(unit, p)
				#actions.append(a)
				#attacked = true
#
		#if not attacked:
			#var prox = _reward_for_proximity(unit, cell, players)
			#actions.append({"move_to": cell, "attack_target": null, "score": prox})
#
	#actions.sort_custom(func(a,b): return a.score > b.score)
	#if actions.size() > AI_MAX_BRANCH:
		#actions = actions.slice(0, AI_MAX_BRANCH)
#
	#return actions
#func _find_path_to_cell(reachable_cells: Array, target: Vector2, start: Vector2) -> Array[Vector2]:
	#var path: Array[Vector2] = []
	#var current: Vector2 = target
	#var safety_counter: int = 0
	#const MAX_ITER: int = 100
#
	#while current != start and safety_counter < MAX_ITER:
		#safety_counter += 1
		#path.insert(0, current)
#
		#var next_cell: Vector2 = Vector2(-1, -1)
		#var min_dist: float = INF
#
		#for dir in DIRECTIONS:
			#var neighbor: Vector2 = current - dir
			#if reachable_cells.has(neighbor):
				#var dist: float = (neighbor - start).length()
				#if dist < min_dist:
					#min_dist = dist
					#next_cell = neighbor
#
		#if next_cell == Vector2(-1, -1):
			#push_warning("Path reconstruction failed from %s" % [current])
			#break
#
		#current = next_cell
#
	#if path.is_empty() or path[0] != start:
		#path.insert(0, start)
#
	#return path
#
#func _generate_player_actions(unit: Unit) -> Array:
	#var actions := []
	#var moves = game_board._dijkstra(unit.cell, unit.move_range, false)
	#var enemies := _alive_units("enemy")
#
	#for cell in moves:
		#for e in enemies:
			#if _dist(cell, e.cell) <= unit.attack_range:
				#var a = {"move_to": cell, "attack_target": e}
				#a.score = _simulate_combat_reward(unit, e)
				#actions.append(a)
#
	#actions.sort_custom(func(a,b): return a.score > b.score)
	#if actions.size() > AI_MAX_BRANCH:
		#actions = actions.slice(0, AI_MAX_BRANCH)
#
	#return actions
#
## ================= Action Execution =================
#
#func _execute_ai_action(unit: Unit, action: Dictionary) -> void:
	#if action.move_to != unit.cell:
		#var reachable = game_board._dijkstra(unit.cell, unit.move_range, false)
		#var path = _find_path_to_cell(reachable, action.move_to, unit.cell)
#
		#game_board._units.erase(unit.cell)
		#unit.cell = action.move_to
		#game_board._units[unit.cell] = unit
		#unit.walk_along(path)
		#await unit.walk_finished
#
	#if action.attack_target != null:
		#await _combat_attack(unit, action.attack_target)
#
	#unit_finished_turn(unit)
#
## ================= Helpers =================
#
#func _alive_units(team: String) -> Array:
	#var arr: Array[Unit] = []
	#for u in unit_groups[team]:
		#if is_instance_valid(u) and not u.is_dead:
			#arr.append(u)
	#return arr
#
#func _dist(a: Vector2, b: Vector2) -> int:
	#return abs(a.x-b.x) + abs(a.y-b.y)
#
## ================= Combat =================
#
#var _combat_finished_flag := false
#
#func _on_combat_finished(attacker: Unit, defender: Unit, result: Dictionary) -> void:
	#_combat_finished_flag = true
#
#func _combat_attack(attacker: Unit, defender: Unit) -> void:
	#_combat_finished_flag = false
	#combat_manager.connect("combat_finished", Callable(self, "_on_combat_finished"), CONNECT_ONE_SHOT)
	#combat_manager.start_combat(attacker, defender)
	#while not _combat_finished_flag:
		#await get_tree().process_frame
#
## ================= Utility (UNCHANGED) =================
#
#func _score_enemy_action(unit: Unit, action: Dictionary) -> float:
	#if action.attack_target:
		#return _simulate_combat_reward(unit, action.attack_target)
	#return _reward_for_proximity(unit, action.move_to, _alive_units("player"))
#
#func _score_player_action(unit: Unit, action: Dictionary) -> float:
	#if action.attack_target:
		#return _simulate_combat_reward(unit, action.attack_target)
	#return 0.0
#
#func _reward_for_proximity(unit: Unit, cell: Vector2, targets: Array) -> float:
	#var min_dist := 999.0
	#for t in targets:
		#min_dist = min(min_dist, (cell - t.cell).length())
	#return 10.0 / (min_dist + 1.0)
#
#func _simulate_combat_reward(attacker: Unit, defender: Unit) -> float:
	#var combat_stats := CombatCalculator.calculate_combat_stats(attacker, defender)
	#var damage: float = float(combat_stats.get("dpa", 0))
	#if combat_stats.get("double", false):
		#damage *= 2.0
#
	#var reward := damage * 2.0
	#if damage >= defender.hp:
		#reward += 100.0
#
	#var counter := CombatCalculator.calculate_combat_stats(defender, attacker)
	#var counter_damage: float = float(counter.get("dpa", 0))
	#if counter.get("double", false):
		#counter_damage *= 2.0
	#reward -= counter_damage * 1.5
#
	#if attacker.attack_range > 1:
		#reward += 5.0
#
	#return reward
	
extends Node
class_name TurnManager

@onready var game_board: GameBoard
@onready var combat_manager: CombatManager

signal phase_started(phase_name: String)
signal phase_ended(phase_name: String)
signal battle_ended(winner: String)

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

# ================= DBN Hidden State =================
# Hidden variable 1: Player Intent
var belief_player_intent := {
	"aggressive": 0.4,
	"defensive": 0.4,
	"retreating": 0.2
}

# Hidden variable 2: Threat level per tile
var threat_map := {}   # Dictionary<Vector2, float>

# Hidden variable 3: Probability each player unit will be targeted / is threatening
var target_priority := {}   # Dictionary<int, float>  (unit instance id -> probability)

# ================= Observation History =================
var last_player_observation := {
	"num_attacks": 0,
	"num_waits": 0,
	"avg_forward_movement": 0.0
}

# ================= Phase Management =================

var phases: Array[String] = ["player", "enemy"]
var current_phase_index: int = 0
var turn_count: int = 1
var _phase_ending: bool = false

var unit_groups := {
	"player": [],
	"enemy": []
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
		# Before enemy acts, update DBN beliefs from previous player behavior
		_observe_player_turn()
		_prediction_step()
		_update_step()

		await game_board.phase_transition_finished
		var units: Array[Unit] = _alive_units("enemy")
		if units.is_empty():
			call_deferred("end_phase")
			return
		await _run_ai_phase(units)

func end_phase() -> void:
	if _phase_ending:
		return
	_phase_ending = true

	emit_signal("phase_ended", phases[current_phase_index])

	if _check_battle_end():
		_phase_ending = false
		return

	current_phase_index = (current_phase_index + 1) % phases.size()
	if current_phase_index == 0:
		turn_count += 1

	call_deferred("start_phase", phases[current_phase_index])
	_phase_ending = false

func unit_finished_turn(unit: Unit) -> void:
	unit.has_acted = true
	unit.update_acted_visual()

	var current_phase: String = phases[current_phase_index]

	for u in unit_groups[current_phase]:
		if is_instance_valid(u) and not u.is_dead and not u.has_acted:
			return

	if not _phase_ending:
		call_deferred("end_phase")

func _check_battle_end() -> bool:
	if _alive_units("player").is_empty():
		emit_signal("battle_ended", "enemy")
		return true
	if _alive_units("enemy").is_empty():
		emit_signal("battle_ended", "player")
		return true
	return false

# ================= AI Phase =================

func _run_ai_phase(units: Array[Unit]) -> void:
	for u in units:
		if not is_instance_valid(u) or u.is_dead:
			continue

		await get_tree().create_timer(0.25).timeout

		if u.is_boss:
			await _run_boss_ai(u)
			continue

		var action = _choose_dbn_action(u)
		await _execute_dbn_action(u, action)
		unit_finished_turn(u)

# ================= Boss AI =================

func _run_boss_ai(u: Unit) -> void:
	for p in _alive_units("player"):
		var dist = abs(u.cell.x - p.cell.x) + abs(u.cell.y - p.cell.y)
		if dist <= u.attack_range:
			await _combat_attack(u, p)
			unit_finished_turn(u)
			return

	var moves = game_board._dijkstra(u.cell, u.move_range, false)

	for move_cell in moves:
		for p in _alive_units("player"):
			var dist = abs(move_cell.x - p.cell.x) + abs(move_cell.y - p.cell.y)
			if dist <= u.attack_range:
				var path = _find_path_to_cell(moves, move_cell, u.cell)

				game_board._units.erase(u.cell)
				u.cell = move_cell
				game_board._units[u.cell] = u

				u.walk_along(path)
				await u.walk_finished

				await _combat_attack(u, p)

				unit_finished_turn(u)
				return

	unit_finished_turn(u)

# =========================================================
# ================= DBN OBSERVATION MODEL =================
# =========================================================

func _observe_player_turn() -> void:
	# Simple approximation of observed player behavior.
	# Replace this with your actual player action logs if available.

	var num_attacks := 0
	var num_waits := 0
	var total_forward := 0.0
	var counted := 0

	for p in _alive_units("player"):
		if not is_instance_valid(p) or p.is_dead:
			continue

		# If you track actual player action history, use that instead.
		# Placeholder logic:
		if p.has_acted:
			num_attacks += 1

		# Estimate forward pressure by closeness to nearest enemy
		var nearest_enemy_dist := 999
		for e in _alive_units("enemy"):
			var d = _dist(p.cell, e.cell)
			if d < nearest_enemy_dist:
				nearest_enemy_dist = d

		total_forward += max(0, 10 - nearest_enemy_dist)
		counted += 1

	last_player_observation["num_attacks"] = num_attacks
	last_player_observation["num_waits"] = num_waits
	last_player_observation["avg_forward_movement"] = (total_forward / max(1, counted))

# =========================================================
# ================= DBN TRANSITION MODEL ==================
# =========================================================

func _prediction_step() -> void:
	# Transition model P(X_t | X_t-1)
	# Predict new intent beliefs before incorporating observations.

	var prev = belief_player_intent.duplicate()

	var new_aggressive = (
		prev["aggressive"] * 0.70 +
		prev["defensive"] * 0.20 +
		prev["retreating"] * 0.10
	)

	var new_defensive = (
		prev["aggressive"] * 0.20 +
		prev["defensive"] * 0.60 +
		prev["retreating"] * 0.20
	)

	var new_retreating = (
		prev["aggressive"] * 0.10 +
		prev["defensive"] * 0.20 +
		prev["retreating"] * 0.70
	)

	belief_player_intent["aggressive"] = new_aggressive
	belief_player_intent["defensive"] = new_defensive
	belief_player_intent["retreating"] = new_retreating

	_normalize_intent_beliefs()

# =========================================================
# ================= DBN UPDATE / INFERENCE ================
# =========================================================

func _update_step() -> void:
	# Observation model P(E_t | X_t)
	# Update beliefs using observed player behavior.

	var attacks = last_player_observation["num_attacks"]
	var forward = last_player_observation["avg_forward_movement"]

	# Likelihood estimates
	var likelihood_aggressive = 1.0 + attacks * 0.35 + forward * 0.08
	var likelihood_defensive = 1.0 + max(0, 2 - attacks) * 0.20
	var likelihood_retreating = 1.0 + max(0, 3 - forward) * 0.15

	belief_player_intent["aggressive"] *= likelihood_aggressive
	belief_player_intent["defensive"] *= likelihood_defensive
	belief_player_intent["retreating"] *= likelihood_retreating

	_normalize_intent_beliefs()

	_rebuild_threat_map()
	_rebuild_target_priority()

func _normalize_intent_beliefs() -> void:
	var total = (
		belief_player_intent["aggressive"] +
		belief_player_intent["defensive"] +
		belief_player_intent["retreating"]
	)

	if total <= 0:
		belief_player_intent = {
			"aggressive": 0.4,
			"defensive": 0.4,
			"retreating": 0.2
		}
		return

	for k in belief_player_intent.keys():
		belief_player_intent[k] /= total

# =========================================================
# ================= THREAT MAP INFERENCE ==================
# =========================================================

func _rebuild_threat_map() -> void:
	threat_map.clear()

	for p in _alive_units("player"):
		if not is_instance_valid(p) or p.is_dead:
			continue

		var reachable = game_board._dijkstra(p.cell, p.move_range, false)

		for tile in reachable:
			var dist = _dist(tile, p.cell)
			var tile_threat = 1.0

			if dist <= p.move_range + p.attack_range:
				tile_threat += 2.0

			# Adjust by inferred player intent
			tile_threat *= (
				1.0 +
				belief_player_intent["aggressive"] * 0.75 -
				belief_player_intent["retreating"] * 0.35
			)

			if not threat_map.has(tile):
				threat_map[tile] = 0.0

			threat_map[tile] += tile_threat

func _rebuild_target_priority() -> void:
	target_priority.clear()

	for e in _alive_units("enemy"):
		if not is_instance_valid(e) or e.is_dead:
			continue

		var score := 0.0

		# Low HP enemies are more likely targets
		var hp_ratio = float(e.hp) / max(1.0, float(e.current_stats.max_hp))
		score += (1.0 - hp_ratio) * 2.0

		# Closer to player front line = higher chance of being targeted
		for p in _alive_units("player"):
			var d = _dist(e.cell, p.cell)
			score += max(0, 6 - d) * 0.25

		score *= (1.0 + belief_player_intent["aggressive"] * 0.5)

		target_priority[e.get_instance_id()] = score

# =========================================================
# ================= ACTION GENERATION =====================
# =========================================================

func _available_actions(unit: Unit) -> Array:
	var actions := []

	var reachable = game_board._dijkstra(unit.cell, unit.move_range, false)

	for cell in reachable:
		if cell == unit.cell:
			continue

		# HARD BLOCK: never allow moving into an occupied cell
		if game_board.is_occupied(cell):
			continue

		actions.append("move_" + str(cell.x) + "_" + str(cell.y))

	for enemy in _alive_units("player"):
		if _dist(unit.cell, enemy.cell) <= unit.attack_range:
			actions.append("attack_" + str(enemy.get_instance_id()))

	actions.append("wait")
	return actions

# =========================================================
# ================= DBN DECISION-MAKING ===================
# =========================================================

func _choose_dbn_action(unit: Unit) -> String:
	var actions = _available_actions(unit)

	if actions.is_empty():
		return "wait"

	var best_action = actions[0]
	var best_score = -INF

	for action in actions:
		var score = _evaluate_action_with_beliefs(unit, action)

		if score > best_score:
			best_score = score
			best_action = action

	print("DBN chose action:", best_action, " score:", best_score)
	return best_action

func _evaluate_action_with_beliefs(unit: Unit, action: String) -> float:
	var score := 0.0

	if action.begins_with("attack_"):
		var id = action.split("_")[1].to_int()

		for player_unit in _alive_units("player"):
			if player_unit.get_instance_id() == id:
				score += _simulate_combat_reward(unit, player_unit)

				# Aggressive player intent encourages proactive attacks
				score += belief_player_intent["aggressive"] * 15.0
				score -= belief_player_intent["retreating"] * 5.0

				break

	elif action.begins_with("move_"):
		var parts = action.split("_")
		var target = Vector2(parts[1].to_int(), parts[2].to_int())

		var tile_threat = threat_map.get(target, 0.0)

		# Prefer lower threat if player is aggressive
		score -= tile_threat * 1.8

		# Encourage moving toward high-value targets
		for p in _alive_units("player"):
			var d = _dist(target, p.cell)
			score += max(0, 8 - d) * 1.2

		# If this enemy is likely to be targeted, avoid dangerous tiles
		var self_target_prob = target_priority.get(unit.get_instance_id(), 0.0)
		score -= self_target_prob * tile_threat * 0.5

	elif action == "wait":
		score -= 10.0

	return score

# =========================================================
# ================= ACTION EXECUTION ======================
# =========================================================

func _execute_dbn_action(unit: Unit, action: String) -> void:
	if action.begins_with("move_"):
		var parts = action.split("_")
		var target = Vector2(parts[1].to_int(), parts[2].to_int())

		var reachable = game_board._dijkstra(unit.cell, unit.move_range, false)
		var path = _find_path_to_cell(reachable, target, unit.cell)

		game_board._units.erase(unit.cell)
		unit.cell = target
		game_board._units[target] = unit

		unit.walk_along(path)
		await unit.walk_finished

		# After moving, check if any player is now in range and attack best one
		var best_target: Unit = null
		var best_score := -INF

		for p in _alive_units("player"):
			if _dist(unit.cell, p.cell) <= unit.attack_range:
				var s = _simulate_combat_reward(unit, p)
				if s > best_score:
					best_score = s
					best_target = p

		if best_target != null:
			await _combat_attack(unit, best_target)

	elif action.begins_with("attack_"):
		var id = action.split("_")[1].to_int()

		for enemy in _alive_units("player"):
			if enemy.get_instance_id() == id:
				await _combat_attack(unit, enemy)
				break

	elif action == "wait":
		pass

# ================= Helpers =================

func _alive_units(team: String) -> Array:
	var arr: Array[Unit] = []
	for u in unit_groups[team]:
		if is_instance_valid(u) and not u.is_dead:
			arr.append(u)
	return arr

func _dist(a: Vector2, b: Vector2) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _find_path_to_cell(reachable_cells: Array, target: Vector2, start: Vector2) -> Array[Vector2]:
	var path: Array[Vector2] = []
	var current: Vector2 = target
	var safety_counter: int = 0
	const MAX_ITER: int = 100

	while current != start and safety_counter < MAX_ITER:
		safety_counter += 1
		path.insert(0, current)

		var next_cell: Vector2 = Vector2(-1, -1)
		var min_dist: float = INF

		for dir in DIRECTIONS:
			var neighbor: Vector2 = current - dir

			if reachable_cells.has(neighbor):
				var dist: float = (neighbor - start).length()

				if dist < min_dist:
					min_dist = dist
					next_cell = neighbor

		if next_cell == Vector2(-1, -1):
			push_warning("Path reconstruction failed from %s" % [current])
			break

		current = next_cell

	if path.is_empty() or path[0] != start:
		path.insert(0, start)

	return path

# ================= Combat =================

var _combat_finished_flag := false

func _on_combat_finished(attacker: Unit, defender: Unit, result: Dictionary) -> void:
	_combat_finished_flag = true

func _combat_attack(attacker: Unit, defender: Unit) -> void:
	_combat_finished_flag = false

	combat_manager.connect("combat_finished", Callable(self, "_on_combat_finished"), CONNECT_ONE_SHOT)
	combat_manager.start_combat(attacker, defender)

	while not _combat_finished_flag:
		await get_tree().process_frame

# ================= Reward Utility =================

func _simulate_combat_reward(attacker: Unit, defender: Unit) -> float:
	var combat_stats := CombatCalculator.calculate_combat_stats(attacker, defender)

	var damage: float = float(combat_stats.get("dpa", 0))

	if combat_stats.get("double", false):
		damage *= 2.0

	var reward := damage * 2.0

	if damage >= defender.hp:
		reward += 100.0

	var counter := CombatCalculator.calculate_combat_stats(defender, attacker)

	var counter_damage: float = float(counter.get("dpa", 0))

	if counter.get("double", false):
		counter_damage *= 2.0

	reward -= counter_damage * 1.5

	if attacker.attack_range > 1:
		reward += 5.0

	return reward
