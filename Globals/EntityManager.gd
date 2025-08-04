extends Node

enum TEAMS {
	RED,
	BLUE,
	NEUTRAL
}

enum UNITS {
	BASIC,
	ROCKET,
	TRUCK,
	TANK,
	HELI,
	PLANE,
	BOAT
}

enum UNITTYPE {
	LAND,
	SEA,
	AIR
}

enum STRUCTURES {
	CITY,
	FORT,
	AIRBASE,
	PORT
}

var current_selection: Unit = null
var path_manager: Node2D
var preview_active := false

func pathfinding_init(pathfinding_node: Node2D):
	path_manager = pathfinding_node
	
func set_unit_path(from_cell: Vector2i, to_cell: Vector2i, type: String) -> Array[Vector2i]:
	if current_selection == null or current_selection.team != TurnManager.current_team_turn:
		print("It's not this unit's turn.")
		return []

	var full_path: Array[Vector2i] = path_manager.get_pathfinding_custom(from_cell, to_cell, type)

	if full_path.is_empty():
		print("Cell out of bounds")
		return []

	# Limit path by current movement points
	# full_path[0] is starting cell — does not consume movement
	var move_limit := current_selection.current_move_points
	var allowed_path: Array[Vector2i] = [full_path[0]]  # Always include start cell

	for i in range(1, full_path.size()):
		if (i - 1) < move_limit:
			allowed_path.append(full_path[i])
		else:
			break

	return allowed_path
