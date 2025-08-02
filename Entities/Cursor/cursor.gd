# Cursor2D.gd (attached to a Node2D or Sprite that visually represents the cursor)
extends Node2D

var current_selection: Unit = null

signal new_selection(unit)

@onready var cursor_collider := $CursorCollider

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
		position = (mouse_pos / GlobalSettings.GRID_SIZE).floor() * GlobalSettings.GRID_SIZE


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Units"):
		print("New unit selected")
		EntityManager.current_selection = area
		new_selection.emit(area)
		current_selection = area


func _on_area_exited(_area: Area2D) -> void:
	if current_selection is Unit:
		print("Unit deselected")
		EntityManager.current_selection = null
		new_selection.emit(null)
		current_selection = null
