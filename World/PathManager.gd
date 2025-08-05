class_name PathManager
extends Node2D

@export var goal_texture: AtlasTexture
@export var arrowhead_up: AtlasTexture
@export var arrowhead_down: AtlasTexture
@export var arrowhead_left: AtlasTexture
@export var arrowhead_right: AtlasTexture
@export var pipe_horizontal: AtlasTexture
@export var pipe_vertical: AtlasTexture
@export var corner_pipe: AtlasTexture

const GRID_WIDTH := 100
const GRID_HEIGHT := 100

var astar := AStarGrid2D.new()
var preview_button_active := false
var current_selection: Unit = null
var start_cell := Vector2i.ZERO
var path_cells: Array[Vector2i] = []

@onready var terrain_tilemap: TileMapLayer = $"../Level/TestLevel/Terrain"
@onready var decor_tilemap: TileMapLayer = $"../Level/TestLevel/Decor"
@onready var cursor: Area2D = $"../Cursor"


func _ready():
	astar.region = Rect2i(Vector2i.ZERO, Vector2i(GRID_WIDTH, GRID_HEIGHT))
	astar.cell_size = Vector2(GlobalSettings.GRID_SIZE, GlobalSettings.GRID_SIZE)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			astar.set_point_solid(Vector2i(x, y), false)

	astar.update()
	EntityManager.pathfinding_init(self)
	cursor.new_selection.connect(update_start_cell)
	TurnManager.turn_started.connect(_on_turn_started)


func _unhandled_input(event):
	if event.is_action_pressed("preview_path"):
		preview_button_active = true

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clear_preview()
		
		if preview_button_active:
			var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
			var clicked_cell = world_to_cell(mouse_pos)

			if astar.is_in_bounds(clicked_cell.x, clicked_cell.y) and current_selection:
				show_path_preview(start_cell, clicked_cell, current_selection.unit_data.unit_type)
				preview_button_active = false


func update_start_cell(unit: Unit) -> void:
	if unit:
		current_selection = unit
		start_cell = world_to_cell(unit.global_position)


func set_current_selection(unit: Unit) -> void:
	current_selection = unit


func get_unit_path(from_cell: Vector2i, to_cell: Vector2i, move_type: String, move_limit: int) -> Array[Vector2i]:
	var full_path := get_pathfinding_custom(from_cell, to_cell, move_type)
	if full_path.is_empty():
		return []

	var allowed_path: Array[Vector2i] = [full_path[0]]
	for i in range(1, full_path.size()):
		if (i - 1) < move_limit:
			allowed_path.append(full_path[i])
		else:
			break

	return allowed_path


func get_pathfinding_custom(from_cell: Vector2i, to_cell: Vector2i, move_type: String) -> Array[Vector2i]:
	var astar_custom := AStarGrid2D.new()
	astar_custom.region = astar.region
	astar_custom.cell_size = astar.cell_size
	astar_custom.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_custom.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_custom.update()

	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var cell = Vector2i(x, y)
			var cost = get_cell_cost_for_type(cell, move_type)

			if int(cost) == 999:
				astar_custom.set_point_solid(cell, true)
			else:
				astar_custom.set_point_solid(cell, false)
				astar_custom.set_point_weight_scale(cell, cost)

	astar_custom.update()
	return astar_custom.get_id_path(from_cell, to_cell)


func show_path_preview(from_cell: Vector2i, to_cell: Vector2i, unit_type: EntityManager.UNITTYPE) -> void:
	var move_type = unit_type_to_string(unit_type)
	var path = get_unit_path(from_cell, to_cell, move_type, current_selection.current_move_points)

	clear_preview()
	path_cells.clear()
	path_cells.assign(path)

	if path_cells.is_empty():
		return

	for i in range(1, path_cells.size()):
		var cell = path_cells[i]
		var sprite = Sprite2D.new()
		sprite.position = Vector2(cell) * GlobalSettings.GRID_SIZE + Vector2(GlobalSettings.GRID_SIZE / 2, GlobalSettings.GRID_SIZE / 2)

		if i == path_cells.size() - 1:
			sprite.texture = get_arrow_texture(cell - path_cells[i - 1])
		else:
			sprite.texture = get_pipe_texture(i, sprite)

		add_child(sprite)


func _on_turn_started(_current_team: EntityManager.TEAMS) -> void:
	clear_preview()
	current_selection = null


# Helpers
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return (world_pos / GlobalSettings.GRID_SIZE).floor()


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * GlobalSettings.GRID_SIZE


func clear_preview() -> void:
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()


func get_cell_cost_for_type(cell: Vector2i, move_type: String) -> float:
	var total_cost := 0.0
	var solid := false

	for tilemap in [terrain_tilemap, decor_tilemap]:
		var tile_data = tilemap.get_cell_tile_data(cell)
		if tile_data:
			var key = "MoveCost" + move_type
			if tile_data.has_custom_data(key):
				var cost = tile_data.get_custom_data(key)
				if typeof(cost) == TYPE_INT:
					if int(cost) == 999:
						solid = true
					else:
						total_cost += float(cost)

	if solid:
		return 999.0
	if total_cost > 0:
		return total_cost
	return 1.0


func unit_type_to_string(unit_type: EntityManager.UNITTYPE) -> String:
	match unit_type:
		EntityManager.UNITTYPE.LAND: return "Land"
		EntityManager.UNITTYPE.SEA: return "Sea"
		EntityManager.UNITTYPE.AIR: return "Air"
		_: return "Land"


func get_arrow_texture(dir: Vector2i) -> Texture2D:
	match dir:
		Vector2i(1, 0): return arrowhead_right
		Vector2i(-1, 0): return arrowhead_left
		Vector2i(0, 1): return arrowhead_down
		Vector2i(0, -1): return arrowhead_up
		_: return arrowhead_right


func get_pipe_texture(i: int, sprite: Sprite2D) -> Texture2D:
	var prev = path_cells[i - 1]
	var curr = path_cells[i]
	var next = path_cells[i + 1]
	
	var dir_prev = curr - prev
	var dir_next = next - curr

	if dir_prev == dir_next:
		if abs(dir_prev.x) == 1:
			sprite.rotation_degrees = 0
			return pipe_horizontal
		elif abs(dir_prev.y) == 1:
			sprite.rotation_degrees = 0
			return pipe_vertical
	else:
		sprite.rotation_degrees = get_corner_rotation(dir_prev, dir_next)
		return corner_pipe

	return pipe_horizontal


func get_corner_rotation(dir_prev: Vector2i, dir_next: Vector2i) -> float:
	if (dir_prev == Vector2i(1, 0) and dir_next == Vector2i(0, 1)) or \
	   (dir_prev == Vector2i(0, -1) and dir_next == Vector2i(-1, 0)):
		return 0
	elif (dir_prev == Vector2i(0, 1) and dir_next == Vector2i(-1, 0)) or \
		 (dir_prev == Vector2i(1, 0) and dir_next == Vector2i(0, -1)):
		return 90
	elif (dir_prev == Vector2i(-1, 0) and dir_next == Vector2i(0, -1)) or \
		 (dir_prev == Vector2i(0, 1) and dir_next == Vector2i(1, 0)):
		return 180
	elif (dir_prev == Vector2i(0, -1) and dir_next == Vector2i(1, 0)) or \
		 (dir_prev == Vector2i(-1, 0) and dir_next == Vector2i(0, 1)):
		return 270
	else:
		return 0
