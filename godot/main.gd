extends Node2D
## Composition root: connects independent gameplay, input, presentation and platform modules.
const RoundModel = preload("res://scripts/round_model.gd")
const Navigation = preload("res://scripts/navigation.gd")
const HouseView = preload("res://scripts/house_view.gd")
const GameHud = preload("res://scripts/game_hud.gd")
const GameInput = preload("res://scripts/game_input.gd")
const Preferences = preload("res://scripts/preferences.gd")
const GameAudio = preload("res://scripts/game_audio.gd")
const WebPlatform = preload("res://scripts/web_platform.gd")
var round := RoundModel.new(Navigation.new())
var preferences := Preferences.new()
var platform := WebPlatform.new()
var view: Node2D
var hud: CanvasLayer
var controls: Node
var audio: Node


func _ready() -> void:
	audio = GameAudio.new()
	add_child(audio)
	view = HouseView.new()
	view.state = round
	add_child(view)
	controls = GameInput.new()
	add_child(controls)
	hud = GameHud.new()
	add_child(hud)
	controls.joystick = hud.joystick
	_connect_intents()
	get_viewport().size_changed.connect(_resize)
	_resize()
	_present()


func _connect_intents() -> void:
	round.sound_requested.connect(audio.play_tone)
	round.round_started.connect(platform.start_round)
	round.round_finished.connect(_on_round_finished)
	controls.investigate_requested.connect(round.inspect)
	controls.auto_fire_requested.connect(round.fire_auto)
	controls.pause_requested.connect(_toggle_pause)
	controls.fire_requested.connect(
		func(position: Vector2): round.fire(position - view.world_offset)
	)
	controls.aim_changed.connect(
		func(position: Vector2):
			var direction: Vector2 = position - view.world_offset - round.player
			if direction.length() > 1:
				round.aim = direction.normalized()
	)
	hud.start_requested.connect(_start_or_resume)
	hud.pause_requested.connect(_toggle_pause)
	hud.investigate_requested.connect(round.inspect)
	hud.fire_requested.connect(round.fire_auto)
	hud.sound_toggled.connect(
		func():
			preferences.toggle_sound()
			_present()
	)
	hud.motion_toggled.connect(
		func():
			preferences.toggle_motion()
			_present()
	)


func _start_or_resume() -> void:
	_release_input()
	if round.paused:
		round.toggle_pause()
	else:
		round.reset()
	_present()


func _toggle_pause() -> void:
	_release_input()
	round.toggle_pause()
	_present()


func _on_round_finished(result: Dictionary) -> void:
	_release_input()
	if result.victory:
		preferences.record_score(result.score)
	platform.finish_round(result)


func _release_input() -> void:
	if is_instance_valid(controls):
		controls.reset()
	if is_instance_valid(hud):
		hud.release_touch()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_input()
		if round.started and not round.paused:
			round.toggle_pause()
		if is_instance_valid(hud):
			_present()


func _resize() -> void:
	_release_input()
	var portrait := get_window().size.x < get_window().size.y
	var target := Vector2i(540, 960) if portrait else Vector2i(1152, 768)
	if get_window().content_scale_size != target:
		get_window().content_scale_size = target
		_resize.call_deferred()
		return
	hud.resize_layout()
	_update_camera()
	_present()


func _process(delta: float) -> void:
	controls.enabled = round.started and not round.paused
	round.step(minf(delta, 0.05), controls.movement(), controls.sprinting())
	_update_camera()
	_present()
	view.queue_redraw()


func _update_camera() -> void:
	var size := get_viewport_rect().size
	var visible := Vector2(size.x, size.y - 350)
	var center := Vector2(size.x / 2, 270 + visible.y / 2)
	var camera := Vector2(
		clampf(round.player.x, visible.x / 2, 1516 - visible.x / 2),
		clampf(round.player.y, visible.y / 2, 1026 - visible.y / 2)
	)
	view.world_offset = center - camera


func _present() -> void:
	audio.muted = preferences.muted
	view.reduced_motion = preferences.reduced_motion
	controls.enabled = round.started and not round.paused
	hud.present(round, preferences)
