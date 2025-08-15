#stat_block.gd
class_name StatBlock
extends Resource

@export var max_hp: int = 0
@export var strength: int = 0
@export var defense: int = 0
@export var speed: int = 0
@export var dexterity: int = 0 #accurcy 
@export var charisma: int = 0 
@export var faith: int = 0 #like luck but more on theme

func copy() -> StatBlock:
	var new_block = StatBlock.new()
	new_block.max_hp = max_hp
	new_block.strength = strength
	new_block.defense = defense
	new_block.speed = speed
	new_block.dexterity = dexterity
	new_block.charisma = charisma
	new_block.faith = faith
	return new_block
