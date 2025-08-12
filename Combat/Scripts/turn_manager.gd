extends Node
class_name TurnManager

signal phase_started(phase_name: String)
signal phase_ended(phase_name: String)
signal battle_ended(winner: String)

var phases = ["player", "enemy"] # add "ally" if needed
var current_phase_index := 0
var _phase_ending = false

var unit_groups := {
	"player": [],
	"enemy": []
}

func _ready():
	start_phase(phases[current_phase_index])

func start_phase(phase_name: String):
	emit_signal("phase_started", phase_name)
	print("Starting phase:", phase_name)
	
	var units = unit_groups.get(phase_name, [])
	units = units.filter(func(u):
		return is_instance_valid(u) and not u.is_dead
	)
	
	if units.is_empty():
		end_phase()
		return
	
	if phase_name == "player":
		# Give control to player
		for u in units:
			u.reset_turn()
		# Wait for player actions to finish; call end_phase() manually from last player action
	else:
		# Enemy/AI phase
		_run_ai_phase(units)

func _run_ai_phase(units: Array):
	for u in units:
		if not is_instance_valid(u) or u.is_dead:
			continue
		await get_tree().create_timer(0.5).timeout # wait half a second
		#u.take_turn()
	end_phase()

func end_phase():
	if _phase_ending:
		print("Ignoring repeated end_phase call")
		return
	_phase_ending = true

	print("end_phase called, current phase:", phases[current_phase_index])
	
	emit_signal("phase_ended", phases[current_phase_index])
	current_phase_index = (current_phase_index + 1) % phases.size()
	print("Switched to phase index:", current_phase_index)

	if _check_battle_end():
		_phase_ending = false
		return
	
	start_phase(phases[current_phase_index])
	_phase_ending = false



func _check_battle_end() -> bool:
	if unit_groups["enemy"].filter(func(u): return is_instance_valid(u) and not u.is_dead).is_empty():
		emit_signal("battle_ended", "player")
		return true
	elif unit_groups["player"].filter(func(u): return is_instance_valid(u) and not u.is_dead).is_empty():
		emit_signal("battle_ended", "enemy")
		return true
	return false

func unit_finished_turn(unit: Unit) -> void:
	unit.has_acted = true
	unit.update_acted_visual()

	var current_phase = phases[current_phase_index]
	var remaining = unit_groups[current_phase].filter(
		func(u):
			return is_instance_valid(u) and not u.is_dead and not u.has_acted
	)
	if remaining.is_empty():
		end_phase()
