#Unit.gd
class_name Unit
extends Path2D
@onready var hp_bar: ProgressBar = $PathFollow2D/HPBar  
@onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()
signal unit_died(unit) #singal to the gamebaord to remove unit from board, as well as anywhere else the unit may be accessible (units tab, etc)
signal walk_finished ## Emitted when the unit reached the end of a path along which it was walking.

@export var is_enemy: bool = false
@export var is_player: bool = false
@export var is_boss: bool = false

@export var has_moved = false
@export var has_acted = false
var is_dead = false

@export var move_speed := 600.0
@export var grid: Resource ## Shared resource of type Grid, used to calculate map coordinates.

#item stuff
@export var inventory: InventoryData = null
@export var held_items: HeldItemsData = null
@export var equipped_weapon: ItemData = null 
@export var equipped_armor: ItemData = null

@export var active_abilities: Array[AbilityData]
#stat stuff
@export var level: int = 1
@export var xp: int = 0
@export var hp: int = 10

@export var unit_data: UnitData
@export var current_stats: StatBlock
@export var current_class: ClassData


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
## Offset to apply to the skin sprite in pixels.
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

	# Override HP bar fill color for enemies
	if is_enemy:
		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = Color(1.0, 0.2, 0.2)  # Red
		hp_bar.add_theme_stylebox_override("fill", fill_style)

	if not Engine.is_editor_hint():
		curve = Curve2D.new()
	rng.randomize()
	initialize_stats()
	update_hp_bar()
	
	connect("unit_died", self._on_unit_died)


func initialize_stats() -> void:
	if unit_data == null:
		# No unit data assigned, skip or set defaults
		hp = 0
		current_stats = null
		return
	# Assign starting class if not already set
	if current_class == null:
		current_class = unit_data.starting_class
		
	if current_stats == null:
		current_stats = unit_data.base_stats.copy()

	if hp == 0:
		hp = unit_data.base_stats.max_hp

	if current_stats.max_hp == 0:
		current_stats.max_hp = hp

func update_hp_bar() -> void:
	if not is_instance_valid(hp_bar):
		return

	var max_hp_value := 0

	if current_stats != null:
		max_hp_value = current_stats.max_hp
	elif unit_data != null and unit_data.base_stats != null:
		max_hp_value = unit_data.base_stats.max_hp
	else:
		return

	hp_bar.visible = true
	hp_bar.max_value = max_hp_value
	hp_bar.value = hp


func take_damage(amount: int) -> void:
	if current_stats == null:
		return

	hp = max(hp - amount, 0)
	update_hp_bar()

	if hp == 0:
		unit_died.emit(self)

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

func reset_turn():
	has_acted = false
	update_acted_visual()

func _process(delta: float) -> void:
	_path_follow.progress += move_speed * delta
	
	if _path_follow.progress_ratio >= 1.0:
		_is_walking = false
		# Setting this value to 0.0 causes a Zero Length Interval error
		_path_follow.progress = 0.0
		position = grid.calculate_map_position(cell)
		curve.clear_points()
		emit_signal("walk_finished")


## Starts walking along the path.
## path is an array of grid coordinates that the function converts to map coordinates.
func walk_along(path: PackedVector2Array) -> void:
	if path.is_empty():
		emit_signal("walk_finished")
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
		
		if weapon.weapon_type not in current_class.allowed_weapon_types:
			print("⚠ Cannot equip", weapon.name, "- Not allowed for class:", current_class.name)
			return  # Don't equip

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


func unequip_item(item: ItemData) -> void:
	if item == equipped_weapon:
		var weapon := equipped_weapon as WeaponItemData
		weapon.equipped = false
		remove_stat_bonuses(weapon)
		current_stats.speed += weapon.weight
		equipped_weapon = null
		attack_range = 0  # Reset to default if needed

	elif item == equipped_armor:
		var armor := equipped_armor as EquipmentItemData
		armor.equipped = false
		remove_stat_bonuses(armor)
		current_stats.speed += armor.weight
		equipped_armor = null

	print("=== UNEQUIP DEBUG ===")
	print("Unequipped:", item.name)
	print("Equipped Weapon:", equipped_weapon.name if equipped_weapon else "None")
	print("Equipped Armor:", equipped_armor.name if equipped_armor else "None")
	print("Strength:", current_stats.strength, " | Defense:", current_stats.defense, " | Speed:", current_stats.speed)
	print("=====================")


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

func get_slot_for_item(item: ItemData) -> SlotData:
	for slot in held_items.slots:
		if slot.item_data == item:
			return slot
	return null

func use_item(item: ItemData) -> void:
	if item == null:
		return

	var should_destroy := false

	if item is ProvisionItemData:
		should_destroy = item.use(self)
	elif item is WeaponItemData:
		should_destroy = item.use(self)
	elif item is ItemData:
		should_destroy = item.use(self)

	if should_destroy:
		print("Item", item.name, "broke!")
		held_items.remove_item(get_slot_for_item(item))

	update_hp_bar()
	

func get_raw_stats() -> StatBlock:
	var raw := current_stats.copy()
	
	if equipped_weapon and equipped_weapon is WeaponItemData:
		raw.strength -= (equipped_weapon as WeaponItemData).power
		raw.speed += (equipped_weapon as WeaponItemData).weight
	
	if equipped_armor and equipped_armor is EquipmentItemData:
		raw.defense -= (equipped_armor as EquipmentItemData).defense_bonus
		raw.speed += (equipped_armor as EquipmentItemData).weight
	
	return raw

func get_stats_with_abilities() -> StatBlock:
	var stats := get_raw_stats()

	for ability in active_abilities:
		if ability == null:
			continue

		var bonus: Dictionary = ability.get_stat_bonus(self)
		for key in bonus.keys():
			if stats.has(key):
				stats.set(key, stats.get(key) + bonus[key])

	return stats

func get_combat_stat_bonuses() -> Dictionary:
	var bonuses := {
		"hit": 0,
		"crit": 0,
		"avo": 0
	}

	for ability in active_abilities:
		if ability == null:
			continue

		var bonus := ability.get_stat_bonus(self)

		# Only apply bonuses to combat stats, not base ones
		for key in ["hit", "crit", "avo"]:
			if bonus.has(key):
				bonuses[key] += bonus[key]

	return bonuses
	

func get_reward_xp(attacker: Unit, defeated: bool = false) -> int:
	if !is_enemy or is_player:
		# Only enemies reward XP to players or non-enemies
		return 0

	var base_xp: int
	var level_diff = level - attacker.level
	
	if defeated:
		# XP for defeating enemy
		base_xp = 20  # your existing base for defeat

		# XP multipliers based on level difference
		var multiplier := 1.0
		if level_diff <= -4:
			multiplier = 1.5
		elif level_diff == -3:
			multiplier = 1.3
		elif level_diff == -2:
			multiplier = 1.15
		elif level_diff == -1:
			multiplier = 1.05
		elif level_diff == 0:
			multiplier = 1.0
		elif level_diff == 1:
			multiplier = 0.85
		elif level_diff == 2:
			multiplier = 0.7
		elif level_diff == 3:
			multiplier = 0.5
		elif level_diff >= 4:
			multiplier = 0.3

		return max(int(base_xp * multiplier), 1)
	else:
		# XP for hitting enemy (not defeated)
		# Base 5 XP, adjust by level difference per your spec
		if level_diff == 1:
			base_xp = 3
		elif level_diff > 1:
			base_xp = 1
		elif level_diff == -1:
			base_xp = 7
		elif level_diff < -1:
			base_xp = 9
		else:
			base_xp = 5

		return base_xp




func gain_xp(amount: int) -> void:
	xp = min(xp + amount, 100)  # Clamp xp to 100 max for display

	if xp >= 100:
		xp -= 100  # reset xp on level up
		level_up()

func level_up() -> void:
	level += 1
	var gained_stats := []
	
	if unit_data == null or unit_data.growth_rates.size() == 0:
		# fallback if no growth data
		current_stats.max_hp += 1
		hp = min(hp + 1, current_stats.max_hp)
		update_hp_bar()
		return

	for key in unit_data.growth_rates.keys():
		var growth_chance: int = int(unit_data.growth_rates[key])
		var prob := float(growth_chance) / 100.0
		if rng.randf() < prob:
			match key:
				"hp":
					current_stats.max_hp += 1
					hp += 1
					gained_stats.append("hp")
				"strength":
					current_stats.strength += 1
					gained_stats.append("strength")
				"defense":
					current_stats.defense += 1
					gained_stats.append("defense")
				"speed":
					current_stats.speed += 1
					gained_stats.append("speed")
				"dexterity":
					current_stats.dexterity += 1
					gained_stats.append("dexterity")
				"charisma":
					current_stats.charisma += 1
					gained_stats.append("charisma")
				"faith":
					current_stats.faith += 1
					gained_stats.append("faith")
				_:
					pass

	if gained_stats.size() == 0:
		current_stats.max_hp += 1
		hp += 1
		gained_stats.append("hp (default)")

	hp = min(hp, current_stats.max_hp)
	update_hp_bar()

	print("=== LEVEL UP ===")
	print(unit_data.unit_name if unit_data else "Unit", "reached level", level)
	print("Stats increased:", gained_stats)
	print("================")
	
func update_acted_visual() -> void:
	if has_acted:
		# Dim sprite to gray (reduce color and alpha)
		_sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)
	else:
		# Normal color
		_sprite.modulate = Color(1, 1, 1, 1)

func _on_unit_died(dead_unit: Unit) -> void:
	# Since this is the unit's own signal, dead_unit should be self
	if dead_unit == self:
		is_dead = true
		print(name, "died.")
