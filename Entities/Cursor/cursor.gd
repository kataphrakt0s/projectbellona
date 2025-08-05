class_name Cursor extends Node2D

signal new_selection(unit)

var move_preview_mode := false
var attack_preview_mode := false
var last_clicked_cell: Vector2i = Vector2i(-1, -1)
var current_selection: Unit = null
var selection_allowed := true

@onready var cursor_collider := $CursorCollider


func _ready() -> void:
	TurnManager.turn_started.connect(_on_turn_started)


func _unhandled_input(event: InputEvent) -> void:
	if _handle_cancel_input(event):
		return

	if _handle_preview_path_input(event):
		return

	if _handle_preview_attack_input(event):
		return

	if _handle_left_click_input(event):
		return


func _handle_cancel_input(event: InputEvent) -> bool:
	if (move_preview_mode or attack_preview_mode) and (
		event.is_action_pressed("ui_cancel") or
		(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed)
	):
		cancel_move_preview()
		cancel_attack_preview()
		return true
	return false


func _handle_preview_path_input(event: InputEvent) -> bool:
	if event.is_action("preview_path") and current_selection and event.pressed:
		if current_selection.team != TurnManager.current_team_turn:
			print("Not this unit's turn.")
			return true

		move_preview_mode = true
		selection_allowed = false
		last_clicked_cell = Vector2i(-1, -1)
		return true
	return false


func _handle_preview_attack_input(event: InputEvent) -> bool:
	if event.is_action("preview_attack") and current_selection and event.pressed:
		if current_selection.team != TurnManager.current_team_turn:
			print("Not this unit's turn.")
			return true

		attack_preview_mode = not attack_preview_mode
		selection_allowed = not attack_preview_mode

		if attack_preview_mode:
			current_selection.show_attack_range()
		else:
			current_selection.hide_attack_range()
		return true
	return false


func _handle_left_click_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
		var clicked_cell = Vector2i((mouse_pos / GlobalSettings.GRID_SIZE).floor())
		position = clicked_cell * GlobalSettings.GRID_SIZE

		if move_preview_mode and current_selection:
			if clicked_cell == last_clicked_cell:
				current_selection.movement_confirm = true
				move_preview_mode = false
				selection_allowed = true
				current_selection.move_unit(clicked_cell, current_selection.unit_data.unit_type)
			else:
				current_selection.movement_confirm = false
				EntityManager.path_manager.show_path_preview(
					EntityManager.path_manager.world_to_cell(current_selection.global_position),
					clicked_cell,
					current_selection.unit_data.unit_type
				)
				last_clicked_cell = clicked_cell
			return true
	return false


func _on_turn_started(_current_team: EntityManager.TEAMS) -> void:
	clear_selection()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Units") and selection_allowed:
		print("New unit selected")
		EntityManager.current_selection = area
		new_selection.emit(area)
		current_selection = area


func _on_area_exited(_area: Area2D) -> void:
	if move_preview_mode or attack_preview_mode:
		return  # Block deselection during previews

	if current_selection is Unit and selection_allowed:
		print("Unit deselected")
		current_selection.attack_range_visible = false
		current_selection.hide_attack_range()
		EntityManager.current_selection = null
		new_selection.emit(null)
		current_selection = null


func clear_selection():
	current_selection = null


func cancel_move_preview():
	if move_preview_mode:
		print("Move preview mode canceled.")
		move_preview_mode = false
		selection_allowed = true
		last_clicked_cell = Vector2i(-1, -1)
		EntityManager.path_manager.clear_preview()


func cancel_attack_preview():
	if attack_preview_mode:
		print("Attack preview mode canceled.")
		attack_preview_mode = false
		selection_allowed = true
		if current_selection:
			current_selection.hide_attack_range()
