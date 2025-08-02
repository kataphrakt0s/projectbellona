class_name Unit extends Area2D

@export var team: EntityManager.TEAMS = EntityManager.TEAMS.NEUTRAL
@export var unit: EntityManager.UNITS = EntityManager.UNITS.BASIC
@export var unit_type: EntityManager.UNITTYPE = EntityManager.UNITTYPE.LAND
@export var move_speed := 100.0

signal movement_finished

var is_moving := false
var movement_confirm := false

@onready var unit_sprite := $UnitSprite


func _ready() -> void:
	self.add_to_group("Units")
	
	# Load correct unit texture based on unit team and type
	unit_sprite.texture = load(
		"res://Entities/Unit/Resources/{team}/{team}_{type}.tres".format(
			{"team": get_enum_name(EntityManager.TEAMS, team).to_lower(), "type": get_enum_name(EntityManager.UNITS, unit).to_lower()}
		)
	)


func move_unit(to_cell: Vector2i, type: EntityManager.UNITTYPE) -> void:
	if is_moving:
		return
		
	if not movement_confirm:
		print("Movement not confirmed, ignoring move command.")
		return
		
	var from_cell = EntityManager.path_manager.world_to_cell(global_position)
	var path: Array[Vector2i]
	match type:
		EntityManager.UNITTYPE.LAND:
			path = EntityManager.set_land_unit_path(from_cell, to_cell, "Land")
		EntityManager.UNITTYPE.SEA:
			path = EntityManager.set_land_unit_path(from_cell, to_cell, "Sea")
		EntityManager.UNITTYPE.AIR:
			path = EntityManager.set_land_unit_path(from_cell, to_cell, "Air")
	
	if path.size() < 2:
		return  # already there or no path
	
	is_moving = true
	
	for cell in path.slice(1):  # skip current position
		var target_pos = EntityManager.path_manager.cell_to_world(cell)
		
		while global_position.distance_to(target_pos) > 1.0:
			var direction = (target_pos - global_position).normalized()
			global_position += direction * move_speed * get_process_delta_time()
			await get_tree().process_frame
		
		global_position = target_pos
	
	is_moving = false
	movement_confirm = false
	movement_finished.emit()
	
# Helpers
func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for enum_name in enum_dict.keys():
		if enum_dict[enum_name] == value:
			return enum_name
	return "UNKNOWN"
