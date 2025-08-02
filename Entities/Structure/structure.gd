class_name Structure extends Area2D


@export var team: EntityManager.TEAMS = EntityManager.TEAMS.NEUTRAL
@export var structure_type: EntityManager.STRUCTYPES = EntityManager.STRUCTYPES.FORT

@onready var structure_sprite := $StructureSprite

func _ready() -> void:
	self.add_to_group("Structures")
	
	# Load correct unit texture based on unit team and type
	structure_sprite.texture = load(
		"res://Entities/Structure/Resources/{team}/{team}_{type}.tres".format(
			{"team": get_enum_name(EntityManager.TEAMS, team).to_lower(), "type": get_enum_name(EntityManager.STRUCTYPES, structure_type).to_lower()}
		)
	)

# Helpers
func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for enum_name in enum_dict.keys():
		if enum_dict[enum_name] == value:
			return enum_name
	return "UNKNOWN"
