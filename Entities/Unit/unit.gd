class_name Unit extends Area2D

@export var team: EntityManager.TEAMS = EntityManager.TEAMS.NEUTRAL
@export var unit: EntityManager.UNITS = EntityManager.UNITS.BASIC
@export var unit_type: EntityManager.UNITTYPE = EntityManager.UNITTYPE.LAND
@export var move_speed := 100.0
@export var max_move_points: int = 5

signal movement_finished

var is_moving := false
var movement_confirm := false
var current_move_points: int:
	set(value):
		current_move_points = value
		if value <= 0:
			unit_sprite.modulate = Color.DIM_GRAY
		else:
			unit_sprite.modulate = Color.WHITE

@onready var unit_sprite := $UnitSprite


func _ready() -> void:
	self.add_to_group("Units")
	current_move_points = max_move_points  # Initialize move points
	
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
			path = EntityManager.set_unit_path(from_cell, to_cell, "Land")
		EntityManager.UNITTYPE.SEA:
			path = EntityManager.set_unit_path(from_cell, to_cell, "Sea")
		EntityManager.UNITTYPE.AIR:
			path = EntityManager.set_unit_path(from_cell, to_cell, "Air")

	# path includes current cell — remove it before cost calc
	path = path.slice(1)

	# Check if unit has enough movement points
	if path.size() > current_move_points:
		print("Not enough movement points to move there.")
		return

	is_moving = true

	for cell in path:
		var target_pos = EntityManager.path_manager.cell_to_world(cell)

		while global_position.distance_to(target_pos) > 1.0:
			var direction = (target_pos - global_position).normalized()
			global_position += direction * move_speed * get_process_delta_time()
			await get_tree().process_frame

		global_position = target_pos
		current_move_points -= 1

	is_moving = false
	movement_confirm = false
	movement_finished.emit()


func reset_movement_points() -> void:
	current_move_points = max_move_points


# Helpers
func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for enum_name in enum_dict.keys():
		if enum_dict[enum_name] == value:
			return enum_name
	return "UNKNOWN"
