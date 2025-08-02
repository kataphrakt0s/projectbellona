class_name Unit extends Area2D

@export var team: EntityManager.TEAMS = EntityManager.TEAMS.NEUTRAL
@export var unit_type: EntityManager.UNITTYPES = EntityManager.UNITTYPES.BASIC

@onready var unit_sprite := $UnitSprite


func _ready() -> void:
	self.add_to_group("Units")
	
	# Load correct unit texture based on unit team and type
	unit_sprite.texture = load(
		"res://Entities/Unit/Assets/{team}/{team}_{type}.tres".format(
			{"team": get_enum_name(EntityManager.TEAMS, team).to_lower(), "type": get_enum_name(EntityManager.UNITTYPES, unit_type).to_lower()}
		)
	)

# Helpers
func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for enum_name in enum_dict.keys():
		if enum_dict[enum_name] == value:
			return enum_name
	return "UNKNOWN"
