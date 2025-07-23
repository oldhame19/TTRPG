#stat_block.gd
class_name StatBlock
extends Resource

@export var hp: int = 0
@export var strength: int = 0
@export var defense: int = 0
@export var speed: int = 0
@export var dexterity: int = 0

func copy() -> StatBlock:
	var new_block = StatBlock.new()
	new_block.hp = hp
	new_block.strength = strength
	new_block.defense = defense
	new_block.speed = speed
	new_block.dexterity = dexterity
	return new_block
