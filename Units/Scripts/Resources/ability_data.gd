#static_ability.gd
class_name AbilityData
extends Resource

enum effect_type {NONE, PASSIVE, THRESHOLD, BLESSING}
@export var name: String
@export_multiline var description : String = ""
