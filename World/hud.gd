extends CanvasLayer

func _ready() -> void:
	TurnManager.turn_ended.connect(turn_ended)
	%Cursor.new_selection.connect(new_selection)
	
func turn_ended(_previous_team, current_team):
	%CurrentTeamTurn.text = get_enum_name(EntityManager.TEAMS, current_team)

func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for enum_name in enum_dict.keys():
		if enum_dict[enum_name] == value:
			return enum_name
	return "UNKNOWN"

func new_selection(selection: Node) -> void:
	if not selection:
		%AttackButton.visible = false
		%AttackLabel.visible = false
		%MoveButton.visible = false
		%MoveLabel.visible = false
		%SpawnButton.visible = false
		%SpawnLabel.visible = false
	if selection is Unit:
		%AttackButton.visible = true
		%AttackLabel.visible = true
		%MoveButton.visible = true
		%MoveLabel.visible = true
		%SpawnButton.visible = false
		%SpawnLabel.visible = false
	if selection is Structure:
		%AttackButton.visible = false
		%AttackLabel.visible = false
		%MoveButton.visible = false
		%MoveLabel.visible = false
		%SpawnButton.visible = true
		%SpawnLabel.visible = true
		
