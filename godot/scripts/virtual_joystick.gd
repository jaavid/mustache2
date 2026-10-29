extends Control
## Fixed-origin analogue stick. Owns one finger; other fingers remain available for actions.
signal movement_changed(direction: Vector2)
const TRAVEL := 42.0
const DEAD_ZONE := 0.1
var value := Vector2.ZERO
var _finger := -1


func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "حرکت"
	visibility_changed.connect(
		func():
			if not is_visible_in_tree():
				reset()
	)


func reset() -> void:
	_finger = -1
	_set_value(Vector2.ZERO)


func _set_value(direction: Vector2) -> void:
	value = direction
	movement_changed.emit(value)
	queue_redraw()


func _move(local_position: Vector2) -> void:
	var direction := ((local_position - size / 2) / TRAVEL).limit_length()
	_set_value(Vector2.ZERO if direction.length() < DEAD_ZONE else direction)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# The web/mobile driver may send an emulated mouse event before the real touch.
	# Consume it in the pad so it cannot claim the mouse-drag owner (-2).
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if _finger >= 0 or get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.index == _finger and (not event.pressed or event.canceled):
			reset()
			get_viewport().set_input_as_handled()
		elif event.pressed and get_global_rect().has_point(event.position):
			if _finger == -1:
				_finger = event.index
				_move(event.position - global_position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _finger:
		_move(event.position - global_position)
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	# Mouse support makes the exact same stick usable in local browser previews.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _finger == -1:
			_finger = -2
			_move(event.position)
		elif not event.pressed and _finger == -2:
			reset()
		accept_event()
	elif event is InputEventMouseMotion and _finger == -2:
		_move(event.position)
		accept_event()


func _draw() -> void:
	var center := size / 2
	draw_circle(center, 69, Color(0.07, 0.09, 0.16, 0.75))
	draw_arc(center, 68, 0, TAU, 64, Color("72778b"), 2, true)
	draw_arc(center, 48, 0, TAU, 48, Color(1, 0.84, 0.55, 0.18), 1, true)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(center + direction * 54, center + direction * 60, Color("a8aec4"), 2, true)
	var knob := center + value * TRAVEL
	draw_circle(knob + Vector2(0, 4), 27, Color(0, 0, 0, 0.25))
	draw_circle(knob, 27, Color("d95490") if _finger != -1 else Color("414960"))
	draw_arc(knob, 26, 0, TAU, 40, Color("ffb7d1") if _finger != -1 else Color("a8aec4"), 2, true)
	draw_circle(knob, 7, Color("ffd68d"))
