# stone_interactable_tile.gd
extends InteractableTile
class_name StoneTile

@export var smooth_stone: ItemData = preload("res://Items/ItemResources/Misc/smooth_stone.tres")
@export var jagged_stone: ItemData = preload("res://Items/ItemResources/Misc/jagged_stone.tres")
@export var stack_amount: int = 5

func _ready(): 
	tile_type = TileType.STONES
	requires_adjacent = false
	randomize() # initialize RNG
	_register_tile() # call needed in ready for all interactable tiles 

func interact(unit: Unit) -> void:
	# Always give stones, randomly choose type
	var chosen_item: ItemData = smooth_stone if randi() % 2 == 0 else jagged_stone

	# Reset flag first
	unit.collected_item_this_turn = false

	# Check if held items are full
	if unit.held_items.is_full():
		print("%s cannot carry more stones." % unit.name)
		return

	# Wrap in SlotData
	var item_stack = chosen_item.clone()
	item_stack.stack_size = stack_amount
	var slot := SlotData.new()
	slot.item_data = item_stack
	slot.quantity = stack_amount

	# Add to unit's held items
	unit.held_items.add_hold_item(slot)
	unit.collected_item_this_turn = true
	print("%s collected %d %s" % [unit.name, stack_amount, item_stack.name])
