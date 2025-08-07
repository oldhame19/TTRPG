#static_ability.gd
class_name AbilityData
extends Resource

enum EffectType {NONE, PASSIVE, THRESHOLD, BLESSING}
@export var name: String
@export_multiline var description : String = ""
@export var effect_type: EffectType = EffectType.NONE

@export var stat_bonus: Dictionary = {
	"hp": 0,
	"strength": 0,
	"defense": 0,
	"speed": 0,
	"dexterity": 0,
	"charisma": 0,
	"faith": 0,
	"hit": 0,
	"crit": 0,
	"avo": 0 ,
}

func get_stat_bonus(unit: Unit) -> Dictionary:
	# Default behavior: return bonus only if passive
	if effect_type == EffectType.PASSIVE:
		return stat_bonus
	elif effect_type == EffectType.THRESHOLD:
		return {} # THRESHOLD types override this method to define logic
	return {}
