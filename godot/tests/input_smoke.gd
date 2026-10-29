extends SceneTree
## Integration tests send real viewport touch events; no joystick internals are invoked.
var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)


func touch(index: int, position: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event, true)


func drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	root.push_input(event, true)


func emulated_mouse(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	root.push_input(event, true)


func run() -> void:
	var main_script = load("res://main.gd")
	if main_script == null or not main_script.can_instantiate():
		quit(1)
		return
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(540, 960)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	if not is_instance_valid(game.hud):
		game.free()
		quit(1)
		return
	game.set_process(false)
	game.preferences.muted = true
	await process_frame
	await process_frame
	var stick: Control = game.hud.joystick
	check(not stick.visible, "menu does not expose active joystick")
	var starts := [0]
	game.round.round_started.connect(func(): starts[0] += 1)
	emulated_mouse(game.hud.start_button.get_global_rect().get_center(), true)
	touch(3, game.hud.start_button.get_global_rect().get_center(), true)
	touch(3, game.hud.start_button.get_global_rect().get_center(), false)
	await process_frame
	check(starts[0] == 1, "synthetic mouse plus touch starts one round")
	check(game.round.started and stick.visible, "touch starts round and enables mobile stick")
	check(game.round.fired == 0, "menu tap is not a world shot")
	var center := stick.get_global_rect().get_center()
	emulated_mouse(center + Vector2(21, 0), true)
	touch(0, center + Vector2(21, 0), true)
	check(
		stick.value.is_equal_approx(Vector2(0.5, 0)), "half travel gives half-speed analogue input"
	)
	var previous: Vector2 = game.round.player
	game.round.step(0.05, game.controls.movement())
	check(
		is_equal_approx(game.round.player.x - previous.x, 5.45),
		"analogue movement reaches model without forced normalization"
	)
	var fire_position: Vector2 = game.hud.fire_button.get_global_rect().get_center()
	touch(1, fire_position, true)
	check(game.round.fired == 1, "second finger shoots exactly once")
	check(
		stick.value.is_equal_approx(Vector2(0.5, 0)),
		"shooting finger does not steal movement finger"
	)
	touch(1, fire_position, false)
	check(stick.value.x > 0, "releasing shooting finger keeps movement")
	drag(0, center + Vector2(300, 300))
	check(
		is_equal_approx(stick.value.length(), 1.0), "drag outside pad remains captured and clamped"
	)
	touch(0, center + Vector2(300, 300), false)
	check(stick.value == Vector2.ZERO, "release outside returns stick to center")
	touch(0, center + Vector2(0, -30), true)
	touch(0, center + Vector2(0, -30), false, true)
	check(stick.value == Vector2.ZERO, "canceled touch cannot leave movement stuck")
	touch(0, center + Vector2(30, 0), true)
	touch(1, game.hud.pause_button.get_global_rect().get_center(), true)
	check(game.round.paused and stick.value == Vector2.ZERO, "pause releases active finger")
	game.hud.start_requested.emit()
	check(not game.round.paused and stick.value == Vector2.ZERO, "resume starts from neutral input")
	touch(0, center + Vector2(30, 0), true)
	game.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(
		game.round.paused and stick.value == Vector2.ZERO, "focus loss pauses and releases finger"
	)
	game.hud.start_requested.emit()
	touch(0, center + Vector2(30, 0), true)
	game.hud.resize_layout()
	check(stick.value == Vector2.ZERO, "rotation/layout change releases stick")
	game.round.finish(false)
	game.hud.start_requested.emit()
	check(
		game.round.fired == 0 and stick.value == Vector2.ZERO,
		"replay has no stale touch or projectile"
	)
	game.free()
	await process_frame
	print(("PASS" if failures == 0 else "FAIL") + ": %d touch integration checks" % checks)
	quit(0 if failures == 0 else 1)
