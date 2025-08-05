class_name Structure extends Area2D

signal captured(team: EntityManager.TEAMS)

@export var team: EntityManager.TEAMS = EntityManager.TEAMS.NEUTRAL
@export var structure_type: EntityManager.STRUCTURES = EntityManager.STRUCTURES.FORT
@export var spawn_direction: int = 0 # 0 for right, 1 for down, 2 for left, 3 for up
@export var unit_to_spawn: EntityManager.UNITS = EntityManager.UNITS.ROCKET

var capturing_team: EntityManager.TEAMS = EntityManager.TEAMS.NEUTRAL
var spawned_this_turn := false

@onready var structure_sprite := $StructureSprite
@onready var capture_timer := $CaptureTimer
@onready var spawn_point := $SpawnPoint

func _ready() -> void:
	self.add_to_group("Structures")
	TurnManager.turn_ended.connect(turn_ended)
	
	# Load correct unit texture based on unit team and type
	structure_sprite.texture = load(
		"res://Entities/Structure/Resources/{team}/{team}_{type}.tres".format(
			{"team": get_enum_name(EntityManager.TEAMS, team).to_lower(), "type": get_enum_name(EntityManager.STRUCTURES, structure_type).to_lower()}
		)
	)
	
	_set_spawn_point_position()
	
	_set_spawn_sprite_position()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("spawn_unit") and event.pressed and not spawned_this_turn:
		if %Cursor.current_selection != self:
			return
		print("Spawning unit")
		spawned_this_turn = true
		spawn_unit()


func start_capture(new_team: EntityManager.TEAMS) -> void:
	if new_team	== team:
		return
	capture_timer.start(5)
	capturing_team = new_team

func stop_capture() -> void:
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


func spawn_unit() -> void:
	var unit_data_path := "res://Resources/UnitData/UnitData{unit}.tres".format({
		"unit": get_enum_name(EntityManager.UNITS, unit_to_spawn).to_lower().capitalize()
	})

	if not ResourceLoader.exists(unit_data_path):
		push_error("Unit data not found at: " + unit_data_path)
		return

	var spawn_cell := EntityManager.path_manager.world_to_cell(spawn_point.global_position)

	for unit in get_tree().get_nodes_in_group("Units"):
		var unit_cell := EntityManager.path_manager.world_to_cell(unit.global_position)
		if unit_cell == spawn_cell:
			print("Spawn cell occupied by another unit, aborting spawn.")
			return

	var unit_data: UnitData = load(unit_data_path)
	var unit_scene := preload("res://Entities/Unit/unit.tscn")

	var new_unit: Unit = unit_scene.instantiate()
	new_unit.unit_data = unit_data
	new_unit.team = team
	new_unit.global_position = spawn_point.global_position

	get_node("/root/World/Units").add_child(new_unit)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Units"):
		if area.unit_data.unit_type == EntityManager.UNITTYPE.LAND:
			start_capture(area.team)

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("Units"):
		stop_capture()

func turn_ended(_prev_team, _current_team) -> void:
	spawned_this_turn = false

# Helpers
func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for enum_name in enum_dict.keys():
		if enum_dict[enum_name] == value:
			return enum_name
	return "UNKNOWN"
	
func _set_spawn_point_position() -> void:
	match spawn_direction:
		0: # Right
			spawn_point.position = Vector2(GlobalSettings.GRID_SIZE, 0)
		1: # Down
			spawn_point.position = Vector2(0, GlobalSettings.GRID_SIZE)
		2: # Left
			spawn_point.position = Vector2(-GlobalSettings.GRID_SIZE, 0)
		3: # Up
			spawn_point.position = Vector2(0, -GlobalSettings.GRID_SIZE)
		_:
			spawn_point.position = Vector2.ZERO

func _set_spawn_sprite_position() -> void:
	$SpawnAreaSprite.position = $SpawnPoint.position

func get_global_rect() -> Rect2:
	var size := Vector2(GlobalSettings.GRID_SIZE, GlobalSettings.GRID_SIZE)
	var global_pos := global_position
	return Rect2(global_pos, size)
