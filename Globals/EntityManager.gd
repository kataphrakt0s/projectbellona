extends Node

enum TEAMS {
	RED,
	BLUE,
	NEUTRAL
}

enum UNITTYPES {
	BASIC,
	ROCKET,
	TRUCK,
	TANK,
	HELI,
	PLANE,
	BOAT
}

enum STRUCTYPES {
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

func set_unit_path(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	var path_array: Array[Vector2i] = path_manager.get_pathfinding(from_cell, to_cell)
	if path_array.size() > 0:
		return path_array
	else:
		print("Cell out of bounds")
		return []
