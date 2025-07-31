#unit.data.gd
#bluepirnt for defining starting variables
#does not change at runtime 
class_name UnitData
extends Resource

var is_enemy: bool = false
@export var is_player: bool = false

@export var unit_name: String
@export var starting_class: ClassData
@export var base_stats: StatBlock 
@export var personal_ability: AbilityData = null
@export var growth_rates: Dictionary = {
	"hp": 0,
	"strength": 0,
	"defense": 0,
	"speed": 0,
	"dexterity": 0,
	"charisma": 0,
	"faith" : 0,
}
