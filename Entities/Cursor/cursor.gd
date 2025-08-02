# Cursor2D.gd (attached to a Node2D or Sprite that visually represents the cursor)
extends Node2D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
		position = (mouse_pos / GlobalSettings.GRID_SIZE).floor() * GlobalSettings.GRID_SIZE
