extends Node2D

signal new_selection(unit)

var preview_mode := false
var last_clicked_cell: Vector2i = Vector2i(-1, -1)
var current_selection: Unit = null
var selection_allowed := true

@onready var cursor_collider := $CursorCollider

func _unhandled_input(event: InputEvent) -> void:
	# Cancel preview with right-click or Escape
	if preview_mode:
		if event.is_action_pressed("ui_cancel") or (
			event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
			cancel_preview()
			return
	
	if event.is_action("preview_path") and current_selection and event.pressed:
		if current_selection.team != TurnManager.current_team_turn:
			print("Not this unit's turn.")
			return
		
		preview_mode = true
		selection_allowed = false
		last_clicked_cell = Vector2i(-1, -1)  # reset

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
		var clicked_cell = Vector2i((mouse_pos / GlobalSettings.GRID_SIZE).floor())
		position = clicked_cell * GlobalSettings.GRID_SIZE

		if preview_mode and current_selection:
			if clicked_cell == last_clicked_cell:
				# Confirm movement
				current_selection.movement_confirm = true
				preview_mode = false
				selection_allowed = true
				current_selection.move_unit(clicked_cell, current_selection.unit_type)
			else:
				# Show preview
				current_selection.movement_confirm = false
				EntityManager.path_manager.show_path_preview(
					EntityManager.path_manager.world_to_cell(current_selection.global_position),
					clicked_cell,
					current_selection.unit_type
				)
				last_clicked_cell = clicked_cell



func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Units") and selection_allowed:
		print("New unit selected")
		EntityManager.current_selection = area
		new_selection.emit(area)
		current_selection = area


func _on_area_exited(_area: Area2D) -> void:
	if preview_mode:
		return  # ⚠️ Block deselection during preview
	
	if current_selection is Unit and selection_allowed:
		print("Unit deselected")
		EntityManager.current_selection = null
		new_selection.emit(null)
		current_selection = null

func cancel_preview():
	if preview_mode:
		print("Preview mode canceled.")
		preview_mode = false
		selection_allowed = true
		last_clicked_cell = Vector2i(-1, -1)
		# Clear preview sprites
		EntityManager.path_manager.clear_preview()
