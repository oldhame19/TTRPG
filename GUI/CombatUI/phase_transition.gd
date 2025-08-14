extends CanvasLayer
class_name PhaseTransition

signal phase_animation_finished

@export var player_phase_color: Color   # Set this in the editor
@export var enemy_phase_color: Color

@onready var label = $PhaseLabel
@onready var anim = $AnimationPlayer

func _ready():
	visible = false  # Start hidden
	anim.animation_finished.connect(_on_animation_finished)

func show_phase(phase_name: String):
	visible = true

	# Set label color based on phase
	if phase_name.to_lower() == "player":
		label.self_modulate  = player_phase_color
	elif phase_name.to_lower() == "enemy":
		label.self_modulate = enemy_phase_color
	else:
		label.modulate = Color(1,1,1,1)

	# Set label text to all caps
	label.text = (phase_name + " PHASE").to_upper()
	label.modulate.a = 0.0
	# Play the corresponding animation
	anim.play(phase_name + "_phase")

func _on_animation_finished(anim_name: String):
	visible = false  # Hide after animation finishes
	emit_signal("phase_animation_finished")
