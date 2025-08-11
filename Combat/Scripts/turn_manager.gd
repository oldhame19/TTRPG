extends Node
class_name TurnManager

signal phase_started(phase_name: String)
signal phase_ended(phase_name: String)
signal battle_ended(winner: String)

var phases = ["player", "enemy"] # add "ally" if needed
var current_phase_index := 0

var unit_groups := {} # { "player": [], "enemy": [] }

func _ready():
	start_phase(phases[current_phase_index])

func start_phase(phase_name: String):
	emit_signal("phase_started", phase_name)
	print("Starting phase:", phase_name)
	
	var units = unit_groups.get(phase_name, [])
	units = units.filter(func(u): return is_instance_valid(u) and not u.is_dead)
	
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
		u.take_turn() # Your AI logic inside Unit or AIController
	end_phase()

func end_phase():
	emit_signal("phase_ended", phases[current_phase_index])
	current_phase_index = (current_phase_index + 1) % phases.size()
	
	# Check win/lose before starting next phase
	if _check_battle_end():
		return
	
	start_phase(phases[current_phase_index])

func _check_battle_end() -> bool:
	if unit_groups["enemy"].filter(func(u): return is_instance_valid(u) and not u.is_dead).is_empty():
		emit_signal("battle_ended", "player")
		return true
	elif unit_groups["player"].filter(func(u): return is_instance_valid(u) and not u.is_dead).is_empty():
		emit_signal("battle_ended", "enemy")
		return true
	return false
