extends CanvasLayer

func _ready() -> void:
	TurnManager.turn_ended.connect(turn_ended)
	
func turn_ended(_previous_team, current_team):
	%CurrentTeamTurn.text = get_enum_name(EntityManager.TEAMS, current_team)

func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for enum_name in enum_dict.keys():
		if enum_dict[enum_name] == value:
			return enum_name
	return "UNKNOWN"
