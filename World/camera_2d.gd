extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	zoom = GlobalSettings.ZOOM_FACTOR

func _unhandled_input(event: InputEvent) -> void:
	if _handle_camera_movement(event):
		return


func _handle_camera_movement(event: InputEvent) -> bool:
	if event.is_action("move_camera_up") and event.pressed:
		global_position.y -= 16
		return true
	if event.is_action("move_camera_left") and event.pressed:
		global_position.x -= 16
		return true
	if event.is_action("move_camera_down") and event.pressed:
		global_position.y += 16
		return true
	if event.is_action("move_camera_right") and event.pressed:
		global_position.x += 16
		return true
	return false
