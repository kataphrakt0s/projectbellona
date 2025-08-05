extends Node


signal turn_started(current_team: EntityManager.TEAMS)
signal turn_ended(previous_team: EntityManager.TEAMS, next_team: EntityManager.TEAMS)

var turn_count: int = 0
var current_team_turn: EntityManager.TEAMS = EntityManager.TEAMS.RED

var team_order: Array[EntityManager.TEAMS] = [
	EntityManager.TEAMS.RED,
	EntityManager.TEAMS.BLUE,
]

var team_active: Dictionary = {
	EntityManager.TEAMS.RED: true,
	EntityManager.TEAMS.BLUE: true,
}

func _ready() -> void:
	turn_started.emit(current_team_turn)
	_reset_team_movement(current_team_turn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("end_turn") and event.pressed:
		end_turn()

func end_turn() -> void:
	var previous_team := current_team_turn
	turn_count += 1

	var next_index := team_order.find(current_team_turn)
	for i in range(team_order.size()):
		next_index = (next_index + 1) % team_order.size()
		var next_team = team_order[next_index]
		if team_active.get(next_team, true):
			current_team_turn = next_team
			break
	
	_reset_team_movement(current_team_turn)
	turn_ended.emit(previous_team, current_team_turn)
	turn_started.emit(current_team_turn)

func check_turn() -> EntityManager.TEAMS:
	return current_team_turn

func is_team_turn(team: EntityManager.TEAMS) -> bool:
	return team == current_team_turn

func skip_team(team: EntityManager.TEAMS) -> void:
	team_active[team] = false

func reactivate_team(team: EntityManager.TEAMS) -> void:
	team_active[team] = true

func reset_turn_order() -> void:
	turn_count = 0
	current_team_turn = team_order[0]
	turn_started.emit(current_team_turn)

func _reset_team_movement(team: EntityManager.TEAMS) -> void:
	for unit in get_tree().get_nodes_in_group("Units"):
		if unit.team == team:
			unit.reset_movement_points()
