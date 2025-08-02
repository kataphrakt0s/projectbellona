class_name Structure extends Area2D

signal captured(team: EntityManager.TEAMS)

@export var team: EntityManager.TEAMS = EntityManager.TEAMS.NEUTRAL
@export var structure_type: EntityManager.STRUCTURES = EntityManager.STRUCTURES.FORT

var capturing_team: EntityManager.TEAMS = EntityManager.TEAMS.NEUTRAL

@onready var structure_sprite := $StructureSprite
@onready var capture_timer := $CaptureTimer

func _ready() -> void:
	self.add_to_group("Structures")
	
	# Load correct unit texture based on unit team and type
	structure_sprite.texture = load(
		"res://Entities/Structure/Resources/{team}/{team}_{type}.tres".format(
			{"team": get_enum_name(EntityManager.TEAMS, team).to_lower(), "type": get_enum_name(EntityManager.STRUCTURES, structure_type).to_lower()}
		)
	)

func start_capture(team: EntityManager.TEAMS):
	capture_timer.start(5)
	capturing_team = team

func stop_capture():
	capturing_team = EntityManager.TEAMS.NEUTRAL
	capture_timer.stop()

func _on_capture_timer_timeout() -> void:
	team = capturing_team
	captured.emit(capturing_team)
	
	# Update sprite
	structure_sprite.texture = load(
		"res://Entities/Structure/Resources/{team}/{team}_{type}.tres".format(
			{"team": get_enum_name(EntityManager.TEAMS, team).to_lower(), "type": get_enum_name(EntityManager.STRUCTURES, structure_type).to_lower()}
		)
	)
	
	print("Structure was captured by {team}".format({"team": get_enum_name(EntityManager.TEAMS, team)}))
	

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Units"):
		start_capture(area.team)

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("Units"):
		stop_capture()

# Helpers
func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for enum_name in enum_dict.keys():
		if enum_dict[enum_name] == value:
			return enum_name
	return "UNKNOWN"
