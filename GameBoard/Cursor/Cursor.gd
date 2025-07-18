## Player-controlled cursor. Allows them to navigate the game grid, select units, and move them.
## Supports both keyboard and mouse (or touch) input.
#@tool
class_name Cursor
extends Node2D

var zoom_enabled := true 
## Emitted when clicking on the currently hovered cell or when pressing "ui_accept".
signal accept_pressed(cell)
## Emitted when the cursor moved to a new cell.
signal moved(new_cell)

## Grid resource, giving the node access to the grid size, and more.
@export var grid: Resource
## Time before the cursor can move again in seconds.
@export var ui_cooldown := 0.1
var restricted_cells := {}  # Use Dictionary as Set[Vector2]
@onready var pointer_texture := $PointerTexture
var show_sprite := true  # controls _draw outline

var zoom_minimum = Vector2(.0100001,.0100001)
var zoom_maximum = Vector2(2.500001,2.500001)
var zoom_speed = Vector2(.100001,.100001)
var is_mouse = false

@onready var _timer: Timer = $Timer
@onready var camera = $Camera2D
## Coordinates of the current cell the cursor is hovering.
var cell := Vector2.ZERO:
	set(value):
		var new_cell: Vector2 = grid.grid_clamp(value)

		# Reject movement to cells not in allowed set, if restriction is active
		if restricted_cells.size() > 0 and not restricted_cells.has(new_cell):
			return

		if new_cell.is_equal_approx(cell):
			return

		cell = new_cell
		position = grid.calculate_map_position(cell)
		emit_signal("moved", cell)
		_timer.start()


func _ready() -> void:
	_timer.wait_time = ui_cooldown
	cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

func _process(_delta):
	if(is_mouse):
		var grid_coords = grid.calculate_grid_coordinates(get_global_mouse_position())
		if(cell != grid_coords):
			cell = grid_coords

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if not zoom_enabled:
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if camera.zoom > zoom_minimum:
					camera.zoom -= zoom_speed
					
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if camera.zoom < zoom_maximum:
					camera.zoom += zoom_speed
	# Navigating cells with the mouse.
	if event is InputEventMouseMotion:
		is_mouse = true
	# Trying to select something in a cell.
	elif event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
		emit_signal("accept_pressed", cell)
		get_viewport().set_input_as_handled()

	var should_move := event.is_pressed() 
	if event.is_echo():
		should_move = should_move and _timer.is_stopped()

	if not should_move:
		return
	# Moves the cursor by one grid cell.
	if event.is_action("ui_right"):
		cell += Vector2.RIGHT
		is_mouse = false
	elif event.is_action("ui_up"):
		cell += Vector2.UP
		is_mouse = false
	elif event.is_action("ui_left"):
		cell += Vector2.LEFT
		is_mouse = false
	elif event.is_action("ui_down"):
		cell += Vector2.DOWN
		is_mouse = false

func _draw() -> void:
	if show_sprite:
		draw_rect(Rect2(-grid.cell_size / 2, grid.cell_size), Color.ALICE_BLUE, false, 2.0)

func reset_cursor() -> void:
	if(is_mouse):
		var grid_coords = grid.calculate_grid_coordinates(get_global_mouse_position())
		cell = grid_coords
func set_pointer_visible(visible: bool) -> void:
	if $PointerTexture:
		$PointerTexture.visible = visible

func set_allowed_cells(cells: Array) -> void:
	restricted_cells.clear()
	for c in cells:
		restricted_cells[c] = true
