class_name GameBoard 
extends Node2D

@onready var cursor = $Cursor

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
const OBSTACLE_ATLAS_ID = 2
const MAX_VALUE: int = 99999
const PauseMenu = preload("res://GUI/PauseMenu/Pause Menu.tscn")
const ActionMenu = preload("res://GUI/ActionMenu/Action Menu.tscn")
const UnitInfoPanelScene = preload("res://GUI/UnitInfo/UnitInfoPanel.tscn")
var _current_action_menu: ActionMenu = null
var _current_trade_scene = null
var _unit_info_panel: UnitInfoPanel

## Resource of type Grid.
@export var grid: Resource = preload("res://GameBoard/Resources/Grid.tres")

## Mapping of coordinates of a cell to a reference to the unit it contains.
var _units := {}
var _active_unit: Unit
var _walkable_cells := []
var _attackable_cells := []
var _movement_costs
var _prev_cell
var _prev_position
var _active_trade_target_cell: Vector2 = Vector2(-1, -1)

@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath
@onready var _map: TileMapLayer = $Map
@onready var _cursor: Cursor = $Cursor



func _ready() -> void:
	_movement_costs = _map.get_movement_costs(grid)
	_reinitialize()

	var ui_root = CanvasLayer.new()
	add_child(ui_root)

	_unit_info_panel = UnitInfoPanelScene.instantiate()
	ui_root.add_child(_unit_info_panel)
	_unit_info_panel.visible = false

	# Position UnitInfoPanel in top-left corner with offset
	_unit_info_panel.anchor_left = 0.0
	_unit_info_panel.anchor_top = 0.0
	_unit_info_panel.anchor_right = 0.0
	_unit_info_panel.anchor_bottom = 0.0
	
	_unit_info_panel.position = Vector2(20, 20)



func _unhandled_input(event: InputEvent) -> void:
	if _current_trade_scene != null:
		# Ignore all input while trade UI is active
		return
	
	if _active_unit and event.is_action_pressed("ui_cancel"):
		_deselect_active_unit()
		_clear_active_unit()



func _get_configuration_warning() -> String:
	var warning := ""
	if not grid:
		warning = "You need a Grid resource for this node to work."
	return warning


## Returns true if the cell is occupied by a unit.
func is_occupied(cell: Vector2) -> bool:
	return _units.has(cell)


## Returns an array of cells a given unit can walk using the flood fill algorithm.
func get_walkable_cells(unit: Unit) -> Array:
	return _dijkstra(unit.cell, unit.move_range, false)
	
func get_tradeable_cells(unit: Unit) -> Array:
	if unit == null or unit.grid == null:
		return []
	
	# If trade mode active, only highlight locked trade target cell
	if _current_action_menu and _current_action_menu.trade_mode_active:
		if _active_trade_target_cell != Vector2(-1, -1):
			return [_active_trade_target_cell]
	
	var tradeable_cells := []
	var unit_cell = unit.grid.calculate_grid_coordinates(unit.position)

	for direction in DIRECTIONS:
		var neighbor_cell = unit_cell + direction
		if _units.has(neighbor_cell):
			var neighbor = _units[neighbor_cell]
			if neighbor != null and is_instance_valid(neighbor) and not neighbor.is_enemy:
				tradeable_cells.append(neighbor_cell)

	return tradeable_cells


## Return an array of cells a given unit can attack using dijkstra's and flood fill algorithm
func get_attackable_cells(unit: Unit) -> Array:
	var attackable_cells = []
	var real_walkable_cells = _dijkstra(unit.cell, unit.move_range, true)
	
	## iterate through every single cell and find their partners based on attack range
	for curr_cell in real_walkable_cells:
		for curr_range in range(1, unit.attack_range + 1):
			attackable_cells = attackable_cells + _flood_fill(curr_cell, unit.attack_range)
	
	return attackable_cells.filter(func(i): return i not in real_walkable_cells)


## Helper: recursively search for a Unit instance inside node subtree
func _find_unit_in_tree(node: Node) -> Unit:
	if node is Unit:
		return node
	for child in node.get_children():
		var found_unit = _find_unit_in_tree(child)
		if found_unit != null:
			return found_unit
	return null


## Clears, and refills the _units dictionary with game objects that are on the board.
func _reinitialize() -> void:
	_units.clear()
	
	for child in get_children():
		var unit = _find_unit_in_tree(child)
		if unit == null:
			continue
			
		unit.grid = grid  # assign grid early for unit
		
		# recalc cell and snap position
		unit.cell = unit.grid.calculate_grid_coordinates(unit.position)
		unit.position = unit.grid.calculate_map_position(unit.cell)

		_units[unit.cell] = unit


## Returns an array with all the coordinates of walkable cells based on the max_distance.
func _flood_fill(cell: Vector2, max_distance: int) -> Array:
	var full_array := []
	var wall_array := []
	var stack := [cell]
	while not stack.size() == 0:
		var current = stack.pop_back()
		if not grid.is_within_bounds(current):
			continue
		if current in full_array:
			continue

		var difference: Vector2 = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue

		full_array.append(current)
		for direction in DIRECTIONS:
			var coordinates: Vector2 = current + direction
			
			## This detects the impassable objects we define in the TileSet based on the Atlas ID
			## If you don't want units to attack over walls and only around them comment out this line and put 'continue'
			if _map.get_cell_source_id(coordinates) == OBSTACLE_ATLAS_ID:
				wall_array.append(coordinates)
			
			if coordinates in full_array:
				continue
			if coordinates in stack:
				continue
			
			stack.append(coordinates)
	
	## Filter out all the walls and return attackable cells
	return full_array.filter(func(i): return i not in wall_array)


## Generates a list of walkable cells based on unit movement value and tile movement cost
func _dijkstra(cell: Vector2, max_distance: int, attackable_check: bool) -> Array:
	var curr_unit = _units[cell]
	var movable_cells = [cell] # append our base cell to the array
	var visited = [] # 2d array that keeps track of which cells we've already looked at while running the algorithm
	var distances = [] # shows distance to each cell, might be useful. can omit if you want to
	var previous = [] #2d array that shows you which cell you have to take to get there to get the shortest path. can omit if you want to
	
	for y in range(grid.size.y):
		visited.append([])
		distances.append([])
		previous.append([])
		for x in range(grid.size.x):
			visited[y].append(false)
			distances[y].append(MAX_VALUE)
			previous[y].append(null)
	
	var queue = PriorityQueue.new()
	
	queue.push(cell, 0) #starting cell
	distances[cell.y][cell.x] = 0
	
	var tile_cost
	var distance_to_node
	var occupied_cells = []
	
	while not queue.is_empty():
		var current = queue.pop() #take out the front node
		visited[current.value.y][current.value.x] = true #mark front node as visited
		
		for direction in  DIRECTIONS:
			var coordinates = current.value + direction #Go through all four neighbors of current node
			if grid.is_within_bounds(coordinates):
				if visited[coordinates.y][coordinates.x]:
					continue
				else:
					tile_cost = _movement_costs[coordinates.y][coordinates.x]
					
					distance_to_node = current.priority + tile_cost #calculate tile cost normally
					
					if is_occupied(coordinates):
						if curr_unit.is_enemy != _units[coordinates].is_enemy:
							distance_to_node = current.priority + MAX_VALUE
						elif _units[coordinates].is_wait and attackable_check:
							occupied_cells.append(coordinates)
					
					visited[coordinates.y][coordinates.x] = true
					distances[coordinates.y][coordinates.x] = distance_to_node
				
				if distance_to_node <= max_distance:
					previous[coordinates.y][coordinates.x] = current.value
					movable_cells.append(coordinates)
					queue.push(coordinates, distance_to_node)
	
	return movable_cells.filter(func(i): return i not in occupied_cells)


func _move_active_unit(new_cell: Vector2) -> void:
	if is_occupied(new_cell) or not new_cell in _walkable_cells:
		return
	_units.erase(_active_unit.cell)
	_active_unit.cell = new_cell
	_units[new_cell] = _active_unit
	_deselect_active_unit()
	_active_unit.walk_along(_unit_path.current_path)
	await _active_unit.walk_finished
	if _unit_info_panel and _active_unit:
		_unit_info_panel.update_info(_active_unit)
		_unit_info_panel.visible = true
	#_clear_active_unit()


func _select_unit(cell: Vector2) -> void:
	if _current_action_menu and _current_action_menu.trade_mode_active:
		return  # Block unit selection during trade
	if not _units.has(cell):
		return

	if not _units.has(cell):
		return
	var candidate_unit = _units[cell]
	if candidate_unit == null or not is_instance_valid(candidate_unit):
		return

	_active_unit = candidate_unit
	_prev_cell = cell
	_prev_position = _active_unit.position

	_active_unit.is_selected = true
	
	_walkable_cells = get_walkable_cells(_active_unit)
	_attackable_cells = get_attackable_cells(_active_unit)
	
	_unit_overlay.draw_attackable_cells(_attackable_cells)
	_unit_overlay.draw_walkable_cells(_walkable_cells)
	
	_unit_path.initialize(_walkable_cells)
func _hover_display(cell: Vector2) -> void:
	if !_unit_info_panel:
		return

	# During trade mode
	if _current_action_menu and _current_action_menu.trade_mode_active:
		if _active_unit and _active_unit.cell == cell:
			_unit_info_panel.visible = false
			return

		var valid_trade_cells = get_tradeable_cells(_active_unit)
		if not valid_trade_cells.has(cell):
			_unit_info_panel.visible = false
			return

	# If hovering over a unit (and not in trade mode or hovering self)
	if _units.has(cell):
		var target_unit = _units[cell]
		if target_unit and is_instance_valid(target_unit):
			_unit_info_panel.update_info(target_unit)
			_unit_info_panel.visible = true

			# 🟢 If no unit is selected, show walkable/attackable overlay for hover unit
			if _active_unit == null:
				_walkable_cells = get_walkable_cells(target_unit)
				_attackable_cells = get_attackable_cells(target_unit)
				_unit_overlay.clear()
				_unit_overlay.draw_walkable_cells(_walkable_cells)
				_unit_overlay.draw_attackable_cells(_attackable_cells)
			return

	# ❌ Not hovering a valid unit
	_unit_info_panel.update_info(null)
	_unit_info_panel.visible = false

	if _active_unit == null:
		_walkable_cells.clear()
		_unit_overlay.clear()




func _reset_unit() -> void:
	if _active_unit != null and _active_unit.cell != _prev_cell:
		_active_unit.position = _prev_position
		_units.erase(_active_unit.cell)
		_units[_prev_cell] = _active_unit
		_active_unit.cell = _prev_cell
		_prev_cell = null
		_prev_position = null
		_deselect_active_unit()
		_clear_active_unit()


func _deselect_active_unit() -> void:
	if _current_action_menu and _current_action_menu.trade_mode_active:
		return  # Don’t clear during trade
	_active_unit.is_selected = false
	_unit_overlay.clear()
	_unit_path.stop()


func _clear_active_unit() -> void:
	_active_unit = null
	_walkable_cells.clear()
func _on_Cursor_moved(new_cell: Vector2) -> void:
	if !_unit_info_panel:
		return
	if _current_trade_scene != null:
		return  # lock cursor during trade UI

	if _current_action_menu and _current_action_menu.trade_mode_active:
		# We DO want to show hover info during trade mode
		_hover_display(new_cell)
		return

	# Normal (non-trade) behavior:
	if _active_unit and _active_unit.is_selected:
		_unit_path.draw(_active_unit.cell, new_cell)
	elif _unit_overlay != null and _walkable_cells.size() > 0:
		_walkable_cells.clear()
		_unit_overlay.clear()

	if _units.has(new_cell) and _active_unit == null:
		_hover_display(new_cell)
	else:
		_unit_info_panel.update_info(null)
		_unit_info_panel.visible = false


func _on_Cursor_accept_pressed(cell: Vector2) -> void:
	if _current_trade_scene != null:
		return  # Prevent accept input during trade UI
	if _current_action_menu and _current_action_menu.trade_mode_active:
		if _active_unit == null:
			return  # Prevent crash due to missing active unit

		var active_cell = _active_unit.cell
		cursor.show()
		cursor.process_mode = Node.PROCESS_MODE_INHERIT
		
		_reinitialize()

		if cell in get_tradeable_cells(_active_unit):
			if not _units.has(cell):
				return
			_unit_info_panel.visible = false
			var target_unit = _units[cell]
			if target_unit == null or not is_instance_valid(target_unit):
				return
			if target_unit != _active_unit:
				_current_action_menu.queue_free()

				_current_trade_scene = preload("res://GUI/ActionMenu/trade_ui.tscn").instantiate()
				_current_trade_scene.game_board = self

				_current_trade_scene.set_units(_active_unit, target_unit)
				add_child(_current_trade_scene)

				_active_trade_target_cell = cell  # <-- Lock trade target cell here
				var tradeable_cells = get_tradeable_cells(_active_unit)

				_unit_overlay.draw_tradeable_cells(tradeable_cells)

				_unit_overlay.draw_highlight_cell(_active_trade_target_cell, 2)
				var retained_unit = _active_unit 
				
				_current_trade_scene.trade_closed.connect(func():
					_current_trade_scene.queue_free()
					_current_trade_scene = null

					_active_trade_target_cell = Vector2(-1, -1)  # <-- Reset when trade UI closes
					_unit_overlay.clear_tradeable_cells()
					_active_unit = retained_unit
					
					var action_menu = ActionMenu.instantiate()
					action_menu.unit = retained_unit
					action_menu.game_board = self
					add_child(action_menu)
					_current_action_menu = action_menu
					action_menu.tree_exited.connect(func():
						if not action_menu.trade_mode_active:
							_clear_active_unit()
						_current_action_menu = null))
				
				
				_current_trade_scene.trade_completed.connect(func():
					_clear_active_unit()
					_current_action_menu = null
				)
				
				_current_action_menu.trade_mode_active = false
				_unit_overlay.clear_tradeable_cells()
				return
		else:
			return

		_current_action_menu.trade_mode_active = false
		_unit_overlay.clear_tradeable_cells()
		cursor.reset_cursor()
		cursor.show()

		return

	if not _active_unit and _units.has(cell):
		_select_unit(cell)
	elif _active_unit != null:
		if is_occupied(cell) and _units[cell] == _active_unit:
			_units.erase(_active_unit.cell)
			_units[cell] = _active_unit

			_deselect_active_unit()

			var action_menu = ActionMenu.instantiate()
			action_menu.unit = _active_unit
			action_menu.game_board = self
			add_child(action_menu)

			_current_action_menu = action_menu

			action_menu.tree_exited.connect(func():
				_clear_active_unit()
				_current_action_menu = null)

		elif not is_occupied(cell) and cell in _walkable_cells:
			await _move_active_unit(cell)

			var action_menu = ActionMenu.instantiate()
			action_menu.unit = _active_unit
			action_menu.game_board = self
			add_child(action_menu)
			
			_current_action_menu = action_menu
			action_menu.tree_exited.connect(func():
				_clear_active_unit()
				_current_action_menu = null)

	else:
		var pause_menu = PauseMenu.instantiate()
		add_child(pause_menu)
