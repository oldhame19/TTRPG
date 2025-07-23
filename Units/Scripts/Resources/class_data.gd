#class_data.gd
class_name ClassData
extends Resource

@export var name: String
@export var base_stats: StatBlock #on promotion, for each stat, if the units stats are lower than the base stat, they will be raised to the base stat
@export var move_range: int = 4
@export var class_ability: AbilityData = null
@export var growth_bonus: Dictionary = {
	"hp": 0,
	"strength": 0,
	"defense": 0,
	"speed": 0,
	"dexterity": 0,
}
