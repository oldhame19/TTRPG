extends Node2D
class_name InteractableTile

enum TileType {NONE, STONES, CHEST, DOOR, THRONE}

@export var tile_type: TileType = TileType.NONE
@export var requires_adjacent: bool = false   # check adjacency instead of direct overlap

func _ready():
	_register_tile()

func _register_tile():
	var game_board = get_parent()
	while game_board and not (game_board is GameBoard):
		game_board = game_board.get_parent()
	if game_board:
		# Convert world position to grid coordinates
		var grid_pos = game_board.grid.calculate_grid_coordinates(global_position)
		
		# Initialize interactables dictionary if it doesn't exist yet
		if game_board.interactables == null:
			game_board.interactables = {}
		
		game_board.interactables[grid_pos] = self


	
func interact(unit: Unit) -> void:
	match tile_type:
		TileType.CHEST:
			print("Unit opened chest!")
		TileType.DOOR:
			print("Unit opened door!")
		TileType.STONES:
			print("Unit collected stones!")
		TileType.THRONE:
			print("Unit seized the throne!")
