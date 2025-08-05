class_name Unit
extends Area2D

@export var team: EntityManager.TEAMS = EntityManager.TEAMS.NEUTRAL
@export var unit_data: UnitData
@export var attack_range_color: Color = Color(1, 0, 0, 0.5) # semi-transparent red for attack range
@export var center_color = Color(1, 1, 1, 0.5)  # semi-transparent white for center cell

signal movement_finished

var is_moving := false
var movement_confirm := false
var path_manager: PathManager
var attack_range_visible := false
var current_move_points: int:
	set(value):
		current_move_points = value
		unit_sprite.modulate = Color.WHITE if value > 0 else Color.DIM_GRAY

@onready var unit_sprite := $UnitSprite
@onready var attack_range_overlay := Node2D.new()


func _ready() -> void:
	add_to_group("Units")
	current_move_points = unit_data.max_move_points
	
	unit_sprite.texture = load(
		"res://Entities/Unit/Resources/{team}/{team}_{type}.tres".format({
			"team": get_enum_name(EntityManager.TEAMS, team).to_lower(),
			"type": get_enum_name(EntityManager.UNITS, unit_data.unit).to_lower()
		})
	)
	
	path_manager = %PathManager
	
	# Add the overlay node to this unit for drawing range
	add_child(attack_range_overlay)
	attack_range_overlay.z_index = 1000  # ensure it is drawn above unit sprite
	TurnManager.turn_ended.connect(turn_ended)
	#draw_attack_range()

func move_unit(to_cell: Vector2i, type: EntityManager.UNITTYPE) -> void:
	if is_moving or not movement_confirm:
		if not is_moving:
			print("Movement not confirmed.")
		return

	if path_manager == null:
		push_error("PathManager not assigned.")
		return

	var from_cell = path_manager.world_to_cell(global_position)
	var move_type = EntityManager.unit_type_to_string(type)
	var path = path_manager.get_unit_path(from_cell, to_cell, move_type, current_move_points)

	# Remove starting cell from path for movement
	path = path.slice(1)

	if path.size() > current_move_points:
		print("Not enough movement points.")
		return

	is_moving = true

	for cell in path:
		var target_pos = path_manager.cell_to_world(cell)
		while global_position.distance_to(target_pos) > 1.0:
			var direction = (target_pos - global_position).normalized()
			global_position += direction * unit_data.move_speed * get_process_delta_time()
			await get_tree().process_frame
		global_position = target_pos
		current_move_points -= 1

	is_moving = false
	movement_confirm = false
	movement_finished.emit()

func reset_movement_points() -> void:
	current_move_points = unit_data.max_move_points

# Helpers
func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for enum_name in enum_dict.keys():
		if enum_dict[enum_name] == value:
			return enum_name
	return "UNKNOWN"
	
func show_attack_range() -> void:
	# Clear previous range markers
	for child in attack_range_overlay.get_children():
		child.queue_free()

	var range = unit_data.attack_range
	var cell_size = GlobalSettings.GRID_SIZE

	# Center the overlay on the unit
	attack_range_overlay.position = Vector2.ZERO

	for x_offset in range(-range, range + 1):
		for y_offset in range(-range, range + 1):
			var dist = abs(x_offset) + abs(y_offset)  # Manhattan distance
			if dist <= range:
				var offset_pos = Vector2(x_offset * cell_size, y_offset * cell_size)

				var rect = ColorRect.new()

				if x_offset == 0 and y_offset == 0:
					rect.color = Color(1, 1, 1, 0.5)  # center square
				else:
					rect.color = attack_range_color

				rect.position = Vector2.ZERO
				rect.size = Vector2(cell_size, cell_size)

				var range_marker = Node2D.new()
				range_marker.position = offset_pos
				range_marker.add_child(rect)

				attack_range_overlay.add_child(range_marker)

func hide_attack_range() -> void:
	for child in attack_range_overlay.get_children():
		child.queue_free()

func toggle_attack_range() -> void:
	attack_range_visible = !attack_range_visible
	if attack_range_visible:
		show_attack_range()
	else:
		hide_attack_range()


func turn_ended(previous_team, current_team) -> void:
	if previous_team == team:
		hide_attack_range()
