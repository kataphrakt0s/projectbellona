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
	FACTORY,
	FORT,
	AIRBASE,
	PORT
}

var current_selection: Unit = null
var path_manager: PathManager


func pathfinding_init(pathfinding_node: PathManager) -> void:
	path_manager = pathfinding_node


func request_path(from_cell: Vector2i, to_cell: Vector2i, unit_type: UNITTYPE) -> Array[Vector2i]:
	if current_selection == null or current_selection.team != TurnManager.current_team_turn:
		print("It's not this unit's turn.")
		return []

	var move_limit := current_selection.current_move_points
	var move_type := unit_type_to_string(unit_type)
	return path_manager.get_unit_path(from_cell, to_cell, move_type, move_limit)

func unit_type_to_string(unit_type: UNITTYPE) -> String:
	match unit_type:
		UNITTYPE.LAND: return "Land"
		UNITTYPE.SEA: return "Sea"
		UNITTYPE.AIR: return "Air"
		_: return "Land"
