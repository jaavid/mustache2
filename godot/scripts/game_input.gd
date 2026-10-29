extends Node
## Converts device events to gameplay intents; it never changes score or world state.
signal investigate_requested
signal fire_requested(screen_position: Vector2)
signal auto_fire_requested
signal pause_requested
signal aim_changed(screen_position: Vector2)
const VirtualJoystick = preload("res://scripts/virtual_joystick.gd")
var joystick: VirtualJoystick
var enabled := false


func movement() -> Vector2:
	if not enabled:
		return Vector2.ZERO
	var direction: Vector2 = joystick.value if is_instance_valid(joystick) else Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1
	return direction.limit_length()


func sprinting() -> bool:
	return enabled and Input.is_physical_key_pressed(KEY_SHIFT)


func reset() -> void:
	if is_instance_valid(joystick):
		joystick.reset()


func _unhandled_input(event: InputEvent) -> void:
	# Real screen touches have their own path; their synthetic mouse events must not fire again.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
			pause_requested.emit()
		if not enabled:
			return
		if event.keycode == KEY_E:
			investigate_requested.emit()
		if event.keycode == KEY_SPACE:
			auto_fire_requested.emit()
	if not enabled:
		return
	if event is InputEventMouseMotion:
		aim_changed.emit(event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fire_requested.emit(event.position)
	if event is InputEventScreenTouch and event.pressed:
		fire_requested.emit(event.position)
