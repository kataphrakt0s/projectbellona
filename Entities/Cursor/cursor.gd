# Cursor2D.gd (attached to a Node2D or Sprite that visually represents the cursor)
extends Node2D

signal new_selection(unit)


var current_selection: Unit = null
var selection_allowed := true
var block_next_click := false

@onready var cursor_collider := $CursorCollider

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("preview_path") and current_selection:
		selection_allowed = false
		block_next_click = true
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if block_next_click:
			# First click after preview_path — block and clear flag
			block_next_click = false
			selection_allowed = true
			return  # Don't process this click

		if selection_allowed:
			var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
			position = (mouse_pos / GlobalSettings.GRID_SIZE).floor() * GlobalSettings.GRID_SIZE

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Units") and selection_allowed:
		print("New unit selected")
		EntityManager.current_selection = area
		new_selection.emit(area)
		current_selection = area


func _on_area_exited(_area: Area2D) -> void:
	if current_selection is Unit and selection_allowed:
		print("Unit deselected")
		EntityManager.current_selection = null
		new_selection.emit(null)
		current_selection = null
