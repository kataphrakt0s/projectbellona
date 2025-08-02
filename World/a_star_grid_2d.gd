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
var start_cell := Vector2i.ZERO
var path_cells: Array[Vector2i] = []

@onready var cursor: Area2D = $"../Cursor"

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
	
	cursor.new_selection.connect(update_start_cell)
	EntityManager.pathfinding_init(self)

func _unhandled_input(event):
	if event.is_action_pressed("preview_path"):
		preview_button_active = true

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Clear previous path sprites on left click regardless of preview active
			for child in get_children():
				child.queue_free()
				
			if preview_button_active:
				var mouse_world_pos = get_viewport().get_camera_2d().get_global_mouse_position()
				var clicked_cell = world_to_cell(mouse_world_pos)
				if astar.is_in_bounds(clicked_cell.x, clicked_cell.y) and EntityManager.current_selection:
					show_path_preview(start_cell, clicked_cell)
					EntityManager.preview_active = true
					preview_button_active = false

func show_path_preview(from_cell: Vector2i, to_cell: Vector2i) -> void:
	var id_path = astar.get_id_path(from_cell, to_cell)
	
	# Clear previous sprites
	for child in get_children():
		child.queue_free()
		
	path_cells.clear()
	for point in id_path:
		path_cells.append(point)
		
	var path_len = path_cells.size()
	if path_len == 0:
		return  # no path
	
	for i in range(1, path_len):
		var cell = path_cells[i]
		var sprite = Sprite2D.new()
		sprite.position = Vector2(cell) * GlobalSettings.GRID_SIZE + Vector2(GlobalSettings.GRID_SIZE / 2, GlobalSettings.GRID_SIZE / 2)
		
		# Unused, path starts from adjacent tile
		#if i == 0:
			## Start pipe - use direction to next cell
			#if path_len > 1:
				#var next_cell = path_cells[i + 1]
				#var dir_next = next_cell - cell
				#
				#if dir_next == Vector2i(1, 0) or dir_next == Vector2i(-1, 0):
					#sprite.texture = pipe_horizontal
					#sprite.rotation_degrees = 0
				#elif dir_next == Vector2i(0, 1) or dir_next == Vector2i(0, -1):
					#sprite.texture = pipe_vertical
					#sprite.rotation_degrees = 0
				#else:
					#sprite.texture = corner_pipe
					#sprite.rotation_degrees = 0
			#else:
				## Path length 1, just place a horizontal pipe by default
				#sprite.texture = pipe_horizontal
				#sprite.rotation_degrees = 0
				
		if i == path_len - 1:
			# Arrowhead at destination - direction from previous cell
			var prev_cell = path_cells[i - 1]
			var dir = cell - prev_cell
			
			if dir == Vector2i(1, 0):
				sprite.texture = arrowhead_right
			elif dir == Vector2i(-1, 0):
				sprite.texture = arrowhead_left
			elif dir == Vector2i(0, 1):
				sprite.texture = arrowhead_down
			elif dir == Vector2i(0, -1):
				sprite.texture = arrowhead_up
			else:
				sprite.texture = arrowhead_right
				
		else:
			# Middle path pipes
			var prev_cell = path_cells[i - 1]
			var next_cell = path_cells[i + 1]
			
			var dir_prev = cell - prev_cell
			var dir_next = next_cell - cell
			
			# Debugging directions:
			#print("Index ", i, ": dir_prev=", dir_prev, ", dir_next=", dir_next)
			
			if dir_prev == dir_next:
				# Straight pipe
				if abs(dir_prev.x) == 1:
					sprite.texture = pipe_horizontal
					sprite.rotation_degrees = 0
				elif abs(dir_prev.y) == 1:
					sprite.texture = pipe_vertical
					sprite.rotation_degrees = 0
				else:
					# Unexpected direction - fallback
					sprite.texture = pipe_horizontal
					sprite.rotation_degrees = 0
			else:
				# Corner pipe - determine rotation
				sprite.texture = corner_pipe
				
				if (dir_prev == Vector2i(1, 0) and dir_next == Vector2i(0, 1)) or \
				   (dir_prev == Vector2i(0, -1) and dir_next == Vector2i(-1, 0)):
					sprite.rotation_degrees = 0  # Right -> Down
					
				elif (dir_prev == Vector2i(0, 1) and dir_next == Vector2i(-1, 0)) or \
					 (dir_prev == Vector2i(1, 0) and dir_next == Vector2i(0, -1)):
					sprite.rotation_degrees = 90  # Down -> Left
					
				elif (dir_prev == Vector2i(-1, 0) and dir_next == Vector2i(0, -1)) or \
					 (dir_prev == Vector2i(0, 1) and dir_next == Vector2i(1, 0)):
					sprite.rotation_degrees = 180  # Left -> Up
					
				elif (dir_prev == Vector2i(0, -1) and dir_next == Vector2i(1, 0)) or \
					 (dir_prev == Vector2i(-1, 0) and dir_next == Vector2i(0, 1)):
					sprite.rotation_degrees = 270  # Up -> Right
					
				else:
					# Fallback rotation
					sprite.rotation_degrees = 0
					
		add_child(sprite)

	## Optionally add a special tinted sprite at the goal cell
	#if path_len > 0:
		#var goal_cell = path_cells[-1]
		#var goal_sprite = Sprite2D.new()
		#goal_sprite.texture = goal_texture
		#goal_sprite.position = Vector2(goal_cell) * GlobalSettings.GRID_SIZE + Vector2(GlobalSettings.GRID_SIZE / 2, GlobalSettings.GRID_SIZE / 2)
		#goal_sprite.modulate = Color(1, 0.5, 0.5)
		#add_child(goal_sprite)



# Helpers
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return (world_pos / GlobalSettings.GRID_SIZE).floor()


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * GlobalSettings.GRID_SIZE

func update_start_cell(unit):
	if unit:
		start_cell = world_to_cell(unit.global_position)

func get_pathfinding(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	if astar.is_in_bounds(from_cell.x, from_cell.y) and astar.is_in_bounds(to_cell.x, to_cell.y):
		return astar.get_id_path(from_cell, to_cell)
	return []

func clear_preview():
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
