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

var preview_active := false
var start_cell := Vector2i.ZERO
var path_cells: Array[Vector2i] = []

func _ready():
	# Setup AStar grid
	astar.region = Rect2i(Vector2i.ZERO, Vector2i(GRID_WIDTH, GRID_HEIGHT))
	astar.cell_size = Vector2(GlobalSettings.GRID_SIZE, GlobalSettings.GRID_SIZE)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	
	astar.update()
	
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			astar.set_point_solid(Vector2i(x, y), false)

	astar.update()


func _unhandled_input(event):
	if event.is_action_pressed("preview_path"):  # "preview_path" = X key in Input Map
		preview_active = true

	if event is InputEventMouseButton and event.pressed and preview_active:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_world_pos = get_viewport().get_camera_2d().get_global_mouse_position()
			var clicked_cell = world_to_cell(mouse_world_pos)
			if astar.is_in_bounds(clicked_cell.x, clicked_cell.y):
				show_path_preview(start_cell, clicked_cell)
				preview_active = false


func show_path_preview(from_cell: Vector2i, to_cell: Vector2i) -> void:
	var id_path = astar.get_id_path(from_cell, to_cell)

	for child in get_children():
		child.queue_free()

	path_cells.clear()
	for point in id_path:
		path_cells.append(point)

	for i in range(1, path_cells.size()):
		var cell = path_cells[i]
		var sprite = Sprite2D.new()
		sprite.position = Vector2(cell) * GlobalSettings.GRID_SIZE + Vector2(GlobalSettings.GRID_SIZE / 2, GlobalSettings.GRID_SIZE / 2)

		if i == path_cells.size() - 1:
			# Arrowhead at destination
			var prev_cell = path_cells[i - 1]
			var dir = Vector2(cell.x - prev_cell.x, cell.y - prev_cell.y).normalized()

			if dir == Vector2(1, 0):
				sprite.texture = arrowhead_right
			elif dir == Vector2(-1, 0):
				sprite.texture = arrowhead_left
			elif dir == Vector2(0, 1):
				sprite.texture = arrowhead_down
			elif dir == Vector2(0, -1):
				sprite.texture = arrowhead_up
			else:
				sprite.texture = arrowhead_right

		elif i == 0:
			var next_cell = path_cells[i + 1]
			var dir_next = next_cell - cell

			# Check if the path immediately turns vertically or horizontally
			# Since this is start, just compare direction to horizontal or vertical vector

			if dir_next == Vector2i(1, 0) or dir_next == Vector2i(-1, 0):
				# Straight horizontal pipe start
				sprite.texture = pipe_horizontal
				sprite.rotation_degrees = 0
			elif dir_next == Vector2i(0, 1) or dir_next == Vector2i(0, -1):
				# Straight vertical pipe start
				sprite.texture = pipe_vertical
				sprite.rotation_degrees = 0
			else:
				# In case it's a corner turn (rare on first segment), show corner pipe rotated 0°
				sprite.texture = corner_pipe
				sprite.rotation_degrees = 0

		else:
			var prev_cell = path_cells[i - 1]
			var next_cell = path_cells[i + 1]

			var dir_prev = cell - prev_cell
			var dir_next = next_cell - cell

			if dir_prev == dir_next:
				# Straight pipe
				if abs(dir_prev.x) > 0:
					sprite.texture = pipe_horizontal
					sprite.rotation_degrees = 0
				else:
					sprite.texture = pipe_vertical
					sprite.rotation_degrees = 0
			else:
				# CORNER — exact pair matching
				sprite.texture = corner_pipe

				if (dir_prev == Vector2i(1, 0) and dir_next == Vector2i(0, 1)):
					sprite.texture = corner_pipe
					sprite.rotation_degrees = 0  # Right → Down (base)

				elif (dir_prev == Vector2i(0, 1) and dir_next == Vector2i(1, 0)):
					sprite.texture = corner_pipe
					sprite.rotation_degrees = 180  # Left → Up

		add_child(sprite)


	# Add a special sprite at destination (optional)
	if path_cells.size() > 0:
		var goal_cell = path_cells[-1]
		var goal_sprite = Sprite2D.new()
		goal_sprite.texture = goal_texture
		goal_sprite.position = Vector2(goal_cell) * GlobalSettings.GRID_SIZE + Vector2(GlobalSettings.GRID_SIZE / 2, GlobalSettings.GRID_SIZE / 2)
		goal_sprite.modulate = Color(1, 0.5, 0.5)  # Tint destination differently
		add_child(goal_sprite)

# Helpers

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return (world_pos / GlobalSettings.GRID_SIZE).floor()

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * GlobalSettings.GRID_SIZE + Vector2(GlobalSettings.GRID_SIZE / 2, GlobalSettings.GRID_SIZE / 2)

func turn_direction(from_dir: Vector2, to_dir: Vector2) -> int:
	# Returns +1 for clockwise, -1 for counterclockwise, 0 for straight

	if from_dir == to_dir:
		return 0  # No turn

	# Use grid directions (0, -1), (1, 0), (0, 1), (-1, 0)
	# Map directions to indexes in clockwise order
	var dirs = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

	var from_idx = dirs.find(from_dir)
	var to_idx = dirs.find(to_dir)

	if from_idx == -1 or to_idx == -1:
		return 0  # invalid input; treat as straight

	var delta = (to_idx - from_idx + 4) % 4
	if delta == 1:
		return 1  # clockwise
	elif delta == 3:
		return -1  # counterclockwise
	else:
		return 0  # straight or 180° (treat as straight for pipes)
