## Represents a unit on the game board.
## The board manages its position inside the game grid.
## The unit itself holds stats and a visual representation that moves smoothly in the game world.
@tool
class_name Unit
extends Path2D

signal walk_finished ## Emitted when the unit reached the end of a path along which it was walking.
@export var is_enemy: bool = false
@export var is_player: bool = false
@export var is_wait = false
@export var move_speed := 600.0
@export var grid: Resource ## Shared resource of type Grid, used to calculate map coordinates.

#item stuff
@export var inventory: InventoryData = null
@export var held_items: HeldItemsData = null
@export var equipped_weapon: ItemData = null 
@export var equipped_armor: ItemData = null
#stat stuff
@export var level: int = 1
@export var max_hp: int = 0
@export var unit_data: UnitData
@export var current_stats: StatBlock
@export var current_class: ClassData
@export var active_abilities: Array[AbilityData]

@export var attack_range := 0 #can be modified based on equipped weapon
@export var move_range := 6 #can be removed and read from current class data


## Texture representing the unit.
@export var skin: Texture:
	set(value):
		skin = value
		if not _sprite:
			# This will resume execution after this node's _ready()
			await ready
		_sprite.texture = value
## Offset to apply to the `skin` sprite in pixels.
@export var skin_offset := Vector2.ZERO:
	set(value):
		skin_offset = value
		if not _sprite:
			await ready
		_sprite.position = value
		

func _ready() -> void:
	if held_items == null:
		held_items = HeldItemsData.new()
	set_process(false)
	_path_follow.rotates = false
	
	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)
	
	# We create the curve resource here because creating it in the editor prevents us from
	# moving the unit.
	if not Engine.is_editor_hint():
		curve = Curve2D.new()
	
	initialize_stats()

func initialize_stats() -> void:
	if unit_data == null:
		# No unit data assigned, skip or set defaults
		max_hp = 0
		current_stats = null
		return

	if current_stats == null:
		current_stats = unit_data.base_stats.copy()

	if max_hp == 0:
		max_hp = unit_data.base_stats.hp

	if current_stats.hp == 0:
		current_stats.hp = max_hp
func level_up() -> void:
	level += 1

## Coordinates of the current cell the cursor moved to.
var cell := Vector2.ZERO:
	set(value):
		# When changing the cell's value, we don't want to allow coordinates outside
		#	the grid, so we clamp them
		cell = grid.grid_clamp(value)
## Toggles the "selected" animation on the unit.
var is_selected := false:
	set(value):
		is_selected = value
		if is_selected:
			_anim_player.play("selected")
		else:
			_anim_player.play("idle")

var _is_walking := false:
	set(value):
		_is_walking = value
		set_process(_is_walking)

@onready var _sprite: Sprite2D = $PathFollow2D/Sprite
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _path_follow: PathFollow2D = $PathFollow2D




func _process(delta: float) -> void:
	_path_follow.progress += move_speed * delta
	
	if _path_follow.progress_ratio >= 1.0:
		_is_walking = false
		# Setting this value to 0.0 causes a Zero Length Interval error
		_path_follow.progress = 0.00001
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		emit_signal("walk_finished")


## Starts walking along the `path`.
## `path` is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		return
	
	curve.add_point(Vector2.ZERO)
	for point in path:
		curve.add_point(grid.calculate_map_position(point) - position)
	cell = path[-1]
	_is_walking = true
	

func equip_item(item: ItemData) -> void:
	print("=== EQUIP DEBUG ===")
	print("Before Equip:")
	print("Equipped Weapon:", equipped_weapon.name if equipped_weapon else "None")
	print("Equipped Armor:", equipped_armor.name if equipped_armor else "None")
	print("Strength:", current_stats.strength, " | Defense:", current_stats.defense, " | Speed:", current_stats.speed)

	if item is WeaponItemData:
		var weapon := item as WeaponItemData
		if equipped_weapon and equipped_weapon is WeaponItemData:
			var old_weapon := equipped_weapon as WeaponItemData
			old_weapon.equipped = false
			remove_stat_bonuses(old_weapon)
			current_stats.speed += old_weapon.weight  # Restore old weight

		equipped_weapon = weapon
		weapon.equipped = true
		attack_range = weapon.atk_range
		apply_stat_bonuses(weapon)
		current_stats.speed -= weapon.weight  # Apply new weight

	elif item is EquipmentItemData:
		var equipment := item as EquipmentItemData
		if equipped_armor and equipped_armor is EquipmentItemData:
			var old_equipment := equipped_armor as EquipmentItemData
			old_equipment.equipped = false
			remove_stat_bonuses(old_equipment)
			current_stats.speed += old_equipment.weight  # Restore old weight

		equipped_armor = equipment
		equipment.equipped = true
		apply_stat_bonuses(equipment)
		current_stats.speed -= equipment.weight  # Apply new weight

	print("After Equip:")
	print("Equipped Weapon:", equipped_weapon.name if equipped_weapon else "None")
	print("Equipped Armor:", equipped_armor.name if equipped_armor else "None")
	print("Strength:", current_stats.strength, " | Defense:", current_stats.defense, " | Speed:", current_stats.speed)
	print("===================")




func apply_stat_bonuses(item: ItemData) -> void:
	if item is EquipmentItemData:
		var eq := item as EquipmentItemData
		current_stats.defense += eq.defense_bonus
	elif item is WeaponItemData:
		var wp := item as WeaponItemData
		# Add bonuses if any (e.g., power to strength)
		current_stats.strength += wp.power

func remove_stat_bonuses(item: ItemData) -> void:
	if item is EquipmentItemData:
		var eq := item as EquipmentItemData
		current_stats.defense -= eq.defense_bonus
	elif item is WeaponItemData:
		var wp := item as WeaponItemData
		current_stats.strength -= wp.power
