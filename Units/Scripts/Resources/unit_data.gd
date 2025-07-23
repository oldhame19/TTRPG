#unit.data.gd
class_name UnitData
extends Resource

@export var unit_name: String
@export var starting_class: ClassData
@export var personal_ability: AbilityData = null
@export var stats: StatBlock
@export var growth_rates: Dictionary = {
	"hp": 0,
	"strength": 0,
	"defense": 0,
	"speed": 0,
	"dexterity": 0,
}
